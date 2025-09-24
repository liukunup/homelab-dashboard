# -*- coding: UTF-8 -*-
# author:      Liu Kun
# email:       liukunup@outlook.com
# timestamp:   2025/09/24 19:51:00
# description: 数据转换器

import re
import os
import json
import typing
import argparse

from datetime import datetime
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus
from dotenv import load_dotenv


class AbstractConverter:
    """ 转换器的抽象类 """

    # 数据库
    __host = None
    __port = 3306
    __username = None
    __password = None
    __database = 'dashboard'

    def __init__(self, host, port, username, password, database: typing.Text = 'dashboard'):
        """ 初始化 """
        # 从`.env`文件中加载环境变量
        load_dotenv()
        # 获取数据库连接参数
        self.__host = host or os.environ.get('DB_HOST', 'localhost')
        self.__port = port or int(os.environ.get('DB_PORT', 3306))
        self.__username = username or os.environ.get('DB_USERNAME')
        self.__password = password or os.environ.get('DB_PASSWORD')
        self.__database = database or os.environ.get('DB_DATABASE', 'dashboard')
        # 创建数据库连接
        quoted_password = quote_plus(self.__password)
        self._engine = create_engine(f'mysql+pymysql://{self.__username}:{quoted_password}@{self.__host}:{self.__port}/{self.__database}?charset=utf8mb4',
                                     connect_args={'init_command': 'SET time_zone="+08:00"'})

    def convert(self, **kwargs):
        """ 执行转换 """
        raise NotImplementedError('请在子类中实现该方法')


class DoubleEntryBookkeepingConverter(AbstractConverter):
    """ 预标记分析器：将原始交易映射为复式记账分录 """

    def analyze(self, op: str = 'import'):
        if op != 'import':
            print("[DoubleEntryBookkeepingConverter] 仅支持 import 操作")
            return

        # 获取日期范围（可扩展为命令行参数）
        start_date = input("请输入开始日期 (YYYY-MM-DD): ").strip()
        end_date = input("请输入结束日期 (YYYY-MM-DD): ").strip()

        try:
            datetime.strptime(start_date, "%Y-%m-%d")
            datetime.strptime(end_date, "%Y-%m-%d")
        except ValueError:
            print("[错误] 日期格式不正确，请使用 YYYY-MM-DD 格式。")
            return

        # 1. 查询原始交易
        raw_transactions = self._fetch_raw_transactions(start_date, end_date)
        if not raw_transactions:
            print("[提示] 在指定日期范围内未找到原始交易记录。")
            return

        # 2. 加载所有映射规则（按优先级排序）
        rules = self._load_mapping_rules()

        # 3. 匹配并写入
        matched_count = 0
        unmatched_records = []

        with self._engine.begin() as conn:
            for tx in raw_transactions:
                matched = False
                for rule in rules:
                    if rule['platform'] not in ('all', tx['source']):
                        continue

                    pattern = rule['pattern']
                    scope = rule['scope']
                    target_field = tx['counterparty'] if scope == 'counterparty' else tx['goods']

                    # 简单通配符匹配：将 % 视为 SQL LIKE 通配符
                    # 注意：pattern 已在数据库中存储为 LIKE 模式（如 '%星巴克%'）
                    if target_field and self._like_match(target_field, pattern):
                        # 匹配成功
                        self._insert_transaction_and_entries(conn, tx, rule)
                        matched_count += 1
                        matched = True
                        break

                if not matched:
                    unmatched_records.append(tx)

        # 4. 打印未匹配记录
        print(f"\n[结果] 成功匹配 {matched_count} 条记录，{len(unmatched_records)} 条未匹配。")
        if unmatched_records:
            print("\n[未匹配记录] 请补充映射规则：")
            print(f"{'订单号':<20} {'对方':<20} {'商品':<30} {'金额':<10} {'来源':<10}")
            print("-" * 80)
            for r in unmatched_records:
                print(f"{r['trade_no']:<20} {r['counterparty'] or '':<20} {r['goods']:<30} {r['amount']:<10} {r['source']:<10}")

    def _fetch_raw_transactions(self, start_date: str, end_date: str):
        sql = text("""
            SELECT id, transaction_at, counterparty, goods, income_or_expenditure,
                   amount, trade_no, source
            FROM deb_online_transaction
            WHERE DATE(transaction_at) BETWEEN :start AND :end
              AND delete_at IS NULL
            ORDER BY transaction_at
        """)
        with self._engine.connect() as conn:
            result = conn.execute(sql, {"start": start_date, "end": end_date})
            return [dict(row) for row in result]

    def _load_mapping_rules(self):
        sql = text("""
            SELECT platform, scope, pattern, debit_account_id, credit_account_id,
                   template, priority
            FROM deb_mapping_rule
            WHERE delete_at IS NULL
            ORDER BY priority DESC, id ASC
        """)
        with self._engine.connect() as conn:
            result = conn.execute(sql)
            return [dict(row) for row in result]

    def _like_match(self, value: str, pattern: str) -> bool:
        """
        模拟 SQL LIKE 匹配逻辑（仅支持 % 和 _）
        为简化，将 % 转为 .*，_ 转为 .，然后使用正则
        """
        if not value:
            return False
        # 转义特殊正则字符，但保留 % 和 _
        regex_pattern = re.escape(pattern)
        regex_pattern = regex_pattern.replace(r'\%', '.*').replace(r'\_', '.')
        regex_pattern = f"^{regex_pattern}$"
        return bool(re.match(regex_pattern, value, re.IGNORECASE))

    def _insert_transaction_and_entries(self, conn, tx: dict, rule: dict):
        # 构造摘要
        brief = rule['template']
        brief = brief.replace('{counterparty}', tx['counterparty'] or '')
        brief = brief.replace('{goods}', tx['goods'] or '')

        # 插入主交易
        trans_sql = text("""
            INSERT INTO deb_transaction (transaction_date, brief, reference, status)
            VALUES (:transaction_date, :brief, :reference, 'posted')
        """)
        trans_result = conn.execute(trans_sql, {
            "transaction_date": tx['transaction_at'].date(),
            "brief": brief.strip() or '无摘要',
            "reference": tx['trade_no']
        })
        transaction_id = trans_result.lastrowid

        # 确定借贷方向
        is_income = tx['income_or_expenditure'] == '收入'
        if is_income:
            # 收入：资产增加（借），收入增加（贷）
            debit_account_id = self._get_asset_account_id(tx['source'])
            credit_account_id = rule['credit_account_id']
        else:
            # 支出：费用增加（借），资产减少（贷）
            debit_account_id = rule['debit_account_id']
            credit_account_id = self._get_asset_account_id(tx['source'])

        # 插入借方分录
        entry_sql = text("""
            INSERT INTO deb_transaction_entry (
                transaction_id, account_id, amount, flag, description,
                source, source_id
            ) VALUES (
                :transaction_id, :account_id, :amount, :flag, :description,
                :source, :source_id
            )
        """)
        conn.execute(entry_sql, {
            "transaction_id": transaction_id,
            "account_id": debit_account_id,
            "amount": tx['amount'],
            "flag": "debit",
            "description": "借方分录",
            "source": tx['source'],
            "source_id": str(tx['id'])
        })

        # 插入贷方分录
        conn.execute(entry_sql, {
            "transaction_id": transaction_id,
            "account_id": credit_account_id,
            "amount": tx['amount'],
            "flag": "credit",
            "description": "贷方分录",
            "source": tx['source'],
            "source_id": str(tx['id'])
        })

    def _get_asset_account_id(self, source: str) -> int:
        """ 根据来源返回对应的资产科目 ID """
        source_to_code = {
            'alipay': '103',      # 支付宝余额
            'wechatpay': '104',   # 微信零钱
            'bank': '102',        # 银行存款
            'manual': '101',      # 现金
        }
        code = source_to_code.get(source, '101')
        sql = text("SELECT id FROM deb_account WHERE account_code = :code")
        with self._engine.connect() as conn:
            result = conn.execute(sql, {"code": code}).fetchone()
            if result:
                return result[0]
            else:
                raise ValueError(f"未找到科目编码 {code} 对应的科目ID，请检查 deb_account 表。")


def args_parser():
    """
    命令行参数解析
    :return: 从命令行输入的参数
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', type=str)
    parser.add_argument('--port', type=int, default=3306)
    parser.add_argument('--username', type=str)
    parser.add_argument('--password', type=str)
    parser.add_argument('--database', type=str, default='dashboard')
    parser.add_argument('--type', type=str, default='Frequency', choices=['Frequency', 'PreMark'])
    return parser.parse_args()


def app():
    """ 应用程序 """
    print('-' * 100)
    name = 'HomeLab Dashboard - Converter'
    print(f'[{name}] Usage: python converter.py '
           '--host localhost --port 3306 --username <username> --password <password> --database dashboard '
           '--type <name>')
    print(f'[{name}] 当前运行路径: {os.getcwd()}')
    print(f'[{name}] 开始执行脚本...')
    print('-' * 100)
    # 从命令行获取参数
    args = args_parser()
    # 按要求执行分析
    operator = {
        'Frequency': {
            'name': '频次分析器',
            'class': FrequencyAnalyzer,
        },
        'PreMarkImport': {
            'name': '预标记分析器',
            'class': PreMarkAnalyzer,
            'kwargs': {
                'op': 'import',
            }
        },
        'PreMarkExport': {
            'name': '预标记分析器',
            'class': PreMarkAnalyzer,
            'kwargs': {
                'op': 'export',
            }
        }
    }[args.type]
    print(f'[{name}] 当前转换器: {operator["name"]}')
    print('-' * 100)
    analyzer = operator['class'](host=args.host, port=args.port, username=args.username, password=args.password, database=args.database)
    analyzer.analyze(**operator.get('kwargs', {}))
    print(f'[{name}] 执行完成!')


if __name__ == '__main__':
    # 应用程序入口
    app()
