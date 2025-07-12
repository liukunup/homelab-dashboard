# -*- coding: UTF-8 -*-
# author:      Liu Kun
# email:       liukunup@outlook.com
# timestamp:   2025/1/1 18:24:00
# description: 数据同步器(将各种来源的数据同步到数据库表)

import re
import os
import typing
import argparse
import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.dialects.mysql import insert
from urllib.parse import quote_plus
from dotenv import load_dotenv


class AbstractSynchronizer:
    """ 同步器的抽象类 """

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

    def update(self, from_datasource, to_table, **kwargs):
        """
        从数据源更新/同步到数据库表
        :param fr_datasource: 数据源
        :param to_table: 目标数据库表
        :param kwargs: 预处理参数
        :return: 影响行数
        """
        print(f'数据源: {from_datasource}')
        # 读取 & 预处理
        print(f'预处理参数: {kwargs}')
        df = self.preprocess(from_datasource, **kwargs)
        if df.empty:
            print(f'从数据源 {from_datasource} 未发现有效数据')
            return
        # 添加更新时间
        df['update_time'] = pd.Timestamp.now()
        # 更新/同步到数据库
        rowcount = 0
        with self._engine.begin() as connection:
            rowcount = df.to_sql(to_table, con=connection, if_exists='append', index=False, chunksize=100, method=self.insert_on_conflict_update)
        print(f'同步完成, 影响行数: {rowcount}')
        print('-' * 100)
        return rowcount

    def preprocess(self, datasource, **kwargs):
        """
        数据源预处理
        :param datasource: 数据源
        :param kwargs: 预处理参数
        :return: 数据帧 DataFrame
        """
        raise NotImplementedError('请在子类中实现该方法')

    def insert_on_conflict_update(self, pd_table, conn, keys, data_iter):
        """
        当插入冲突时进行更新
        :param pd_table: 数据表
        :param conn: 数据库连接
        :param keys: 键名列表
        :param data_iter: 数据迭代
        :return: 影响行数
        """
        raise NotImplementedError('请在子类中实现该方法')


class PaySynchronizer(AbstractSynchronizer):
    """ 电子账单: 支付宝/微信支付 """

    def insert_on_conflict_update(self, pd_table, conn, keys, data_iter):
        data = [dict(zip(keys, row)) for row in data_iter]
        stmt = (
            insert(pd_table.table)
            .values(data)
        )
        stmt = stmt.on_duplicate_key_update(timestamp=stmt.inserted.timestamp, category=stmt.inserted.category,
                                            counterparty=stmt.inserted.counterparty, account=stmt.inserted.account,
                                            goods=stmt.inserted.goods,
                                            income_or_expenditure=stmt.inserted.income_or_expenditure,
                                            amount=stmt.inserted.amount, channel=stmt.inserted.channel,
                                            status=stmt.inserted.status, po_seller=stmt.inserted.po_seller,
                                            comments=stmt.inserted.comments, update_time=stmt.inserted.update_time)
        result = conn.execute(stmt)
        return result.rowcount

    @staticmethod
    def csv_filter(path: typing.Text = '.'):
        """
        对账单文件过滤器
        目标是 找到存放目录中符合要求的对账单文件
        :param path: 存放对账单的目录
        :return: 搜索到的对账单文件列表
        """
        if not os.path.exists(path) or not os.access(path, os.R_OK):
            raise RuntimeError(f'The path {path} is invalid.')
        csv_files = list()
        for root, _, files in os.walk(path):
            if root != path: break
            for file in files:
                filename = os.path.join(root, file)
                if re.match(r'微信支付账单\(\d{8}-\d{8}\).csv', file):
                    csv_files.append(['WeChatPay', filename])
                if re.match(r'alipay_record_\d{8}_\d{6}.csv', file):
                    csv_files.append(['Alipay', filename])
                if re.match(r'支付宝交易明细\(\d{8}-\d{8}\).csv', file):
                    csv_files.append(['Alipay', filename])
        return csv_files

    def update(self, from_datasource, to_table, **kwargs):
        """
        从数据源更新/同步到数据库表
        :param fr_datasource: 数据源
        :param to_table: 目标数据库表
        :param kwargs: 预处理参数
        :return: 影响行数
        """
        # 过滤得到对账单文件列表
        csv_files = self.csv_filter(path=from_datasource)
        rowcount = 0
        for _, csv_file in csv_files:
            rowcount += super().update(csv_file, to_table, **kwargs)
        print(f'总影响行数: {rowcount}')
        print('-' * 100)
        return rowcount


class AlipaySynchronizer(PaySynchronizer):
    """ 电子账单: 支付宝 """

    def preprocess(self, datasource, **kwargs):

        # 文件读取(编码格式:GBK; 跳过行数:24)
        df = pd.read_csv(datasource, sep=',', encoding="gbk", skiprows=lambda x: x < 24)

        # 覆盖列名
        df.columns = ['timestamp', 'category', 'counterparty', 'account', 'goods', 'income_or_expenditure', 'amount',
                      'channel', 'status', 'po_transaction', 'po_seller', 'comments', 'unknown']

        # 添加来源
        df.loc[:, 'source'] = kwargs.get('source', 1)

        # 去除多余列
        df = df.drop(labels='unknown', axis=1)

        # 去除行首尾空格
        for k in ['timestamp', 'category', 'counterparty', 'account', 'goods', 'income_or_expenditure', 'channel', 'status',
                  'po_transaction', 'po_seller', 'comments']:
            df[k] = df[k].apply(lambda s: s if not isinstance(s, str) else s.strip())

        # 去除多余制表符
        df['po_transaction'] = df['po_transaction'].apply(lambda s: s.replace('\t', ''))
        df['po_seller'] = df['po_seller'].apply(lambda s: s.replace('\t', ''))

        return df


class WeChatPaySynchronizer(PaySynchronizer):
    """ 电子账单: 微信支付 """

    def preprocess(self, datasource, **kwargs):

        # 文件读取(编码格式:UTF-8; 跳过行数:17)
        df = pd.read_csv(datasource, sep=',', encoding='utf-8', skiprows=lambda x: x < 16)

        # 覆盖列名
        df.columns = ['timestamp', 'category', 'counterparty', 'goods', 'income_or_expenditure',
                      'amount', 'channel', 'status', 'po_transaction', 'po_seller', 'comments']

        # 添加来源
        df.loc[:, 'account'] = None
        df.loc[:, 'source'] = kwargs.get('source', 2)

        # 处理¥符号以及转格式
        df['amount'] = df['amount'].apply(lambda s: float(s.replace('¥', '')))

        # 去除多余制表符
        df['po_transaction'] = df['po_transaction'].apply(lambda s: s.replace('\t', ''))
        df['po_seller'] = df['po_seller'].apply(lambda s: s.replace('\t', ''))

        return df


class SalarySynchronizer(AbstractSynchronizer):
    """ 薪酬福利: 工资/奖金/福利/... """

    def preprocess(self, file, **kwargs):

        # 文件读取
        df = pd.read_excel(file, sheet_name=kwargs.get('sheetName', 'Sheet1'))

        # 覆盖列名
        df.columns = ['dtm', 'company', 'amount', 'category', 'comments']

        return df

    def insert_on_conflict_update(self, pd_table, conn, keys, data_iter):
        data = [dict(zip(keys, row)) for row in data_iter]
        stmt = (
            insert(pd_table.table)
            .values(data)
        )
        stmt = stmt.on_duplicate_key_update(dtm=stmt.inserted.dtm, company=stmt.inserted.company,
                                            amount=stmt.inserted.amount, category=stmt.inserted.category,
                                            comments=stmt.inserted.comments, update_time=stmt.inserted.update_time)
        result = conn.execute(stmt)
        return result.rowcount


class HousingLoanSynchronizer(AbstractSynchronizer):
    """ 房屋贷款: 已还款明细 """

    def preprocess(self, file, **kwargs):

        # 文件读取
        df = pd.read_excel(file, sheet_name=kwargs.get('sheetName', 'Sheet1'))

        # 覆盖列名
        df.columns = ['period', 'organization', 'current_interest_rate', 'lpr_spread',
                      'actual_principal_interest', 'due_principal_interest', 'actual_principal', 'actual_interest',
                      'repayment_date', 'actual_interest_payment_date']

        return df

    def insert_on_conflict_update(self, pd_table, conn, keys, data_iter):
        data = [dict(zip(keys, row)) for row in data_iter]
        stmt = (
            insert(pd_table.table)
            .values(data)
        )
        stmt = stmt.on_duplicate_key_update(period=stmt.inserted.period, organization=stmt.inserted.organization,
                                            current_interest_rate=stmt.inserted.current_interest_rate, lpr_spread=stmt.inserted.lpr_spread,
                                            actual_principal_interest=stmt.inserted.actual_principal_interest,
                                            due_principal_interest=stmt.inserted.due_principal_interest,
                                            actual_principal=stmt.inserted.actual_principal, actual_interest=stmt.inserted.actual_interest,
                                            repayment_date=stmt.inserted.repayment_date, actual_interest_payment_date=stmt.inserted.actual_interest_payment_date,
                                            update_time=stmt.inserted.update_time)
        result = conn.execute(stmt)
        return result.rowcount


def args_parser():
    """
    命令行参数解析器
    :return: 从命令行输入的参数
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', type=str)
    parser.add_argument('--port', type=int, default=3306)
    parser.add_argument('--username', type=str)
    parser.add_argument('--password', type=str)
    parser.add_argument('--database', type=str, default='dashboard')
    parser.add_argument('--path', type=str, default='data')
    parser.add_argument('--type', type=str, choices=['Alipay', 'WeChatPay', 'Salary', 'HousingLoan'])
    return parser.parse_args()


def app():
    """ 应用程序 """
    print('-' * 100)
    name = 'HomeLab Dashboard - Synchronizer'
    print(f'[{name}] Usage: python ./scripts/synchronizer.py '
           '--host localhost --port 3306 --username <username> --password <password> --database dashboard '
           '--path data --type <name>')
    print(f'[{name}] 当前运行路径: {os.getcwd()}')
    print(f'[{name}] 开始执行脚本...')
    print('-' * 100)
    # 解析从命令行输入的参数
    args = args_parser()
    operator = {
        'Alipay': {
            'name': '支付宝',
            'class': AlipaySynchronizer,
            'datasource': 'alipay',
            'table': 'transaction',
            'kwargs': {
                'source': 1
            }
        },
        'WeChatPay': {
            'name': '微信支付',
            'class': WeChatPaySynchronizer,
            'datasource': 'wechatpay',
            'table': 'transaction',
            'kwargs': {
                'source': 2
            }
        },
        'Salary': {
            'name': '收入明细',
            'class': SalarySynchronizer,
            'datasource': '收入明细.xlsx',
            'table': 'salary',
        },
        'HousingLoan': {
            'name': '房屋贷款',
            'class': HousingLoanSynchronizer,
            'datasource': '已还款明细.xlsx',
            'table': 'loan',
        },
    }[args.type]
    print(f'[{name}] 当前同步器: {operator["name"]}')
    print('-' * 100)
    synchronizer = operator['class'](host=args.host, port=args.port, username=args.username, password=args.password, database=args.database)
    synchronizer.update(os.path.join(args.path, operator['datasource']), operator['table'], **operator.get('kwargs', {}))
    print(f'[{name}] 执行完成!')


if __name__ == '__main__':
    # 应用程序入口
    app()
