#!/usr/bin/env python3

# This quick and dirty script will insert random attributes with random data into the HDB
# database. The data inserted is basic and a poor representation of the possible range of
# each tango type, rather its use is to provide a database to run tests against.
#
# The script can be refined for better data in future.

import argparse
import psycopg2
import random
import string
import time

from datetime import datetime
from datetime import timedelta
from random import randint

verbose = False

# following dicts are lookup tables
types = {
    1: "devboolean",
    2: "devshort",
    3: "devlong",
    4: "devfloat",
    5: "devdouble",
    6: "devushort",
    7: "devulong",
    8: "devstring",
    19: "devstate",
    22: "devuchar",
    23: "devlong64",
    24: "devulong64",
    28: "devencoded",
    29: "devenum",
}

format_types = {0: "scalar", 1: "array", 2: "image"}

# range of attributes to make, this should build all possible combinations. Note we
# exclude encoded and enum for now, since these are not fully supported by the
# timescale implementation yet
type_numbers = [1, 2, 3, 4, 5, 6, 7, 8, 19, 22, 23, 24]
format_numbers = [0, 1]
write_numbers = [0, 1, 2, 3]

# This is a fixed string in the schema, so rather than work it out with
# queries etc, we just use this as a postfix
idx_postfix = "_att_conf_id_data_time_idx"


# used to convert att data back for reuse when generating events

db_types = {
    "DEV_BOOLEAN": 1, "DEV_SHORT": 2,
    "DEV_LONG": 3, "DEV_FLOAT": 4, "DEV_DOUBLE": 5, "DEV_USHORT": 6, "DEV_ULONG": 7, "DEV_STRING": 8,
    "DEV_STATE": 19, "DEV_UCHAR": 22, "DEV_LONG64": 23, "DEV_ULONG64": 24, "DEV_ENCODED": 28, "DEV_ENUM": 29,
}

db_formats = {"SCALAR": 0, "SPECTRUM": 1, "IMAGE": 2}
db_write = {"READ": 0, "READ_WITH_WRITE": 1, "WRITE": 2, "READ_WRITE": 3}

def random_string(len=10):
    """
    Create a random string for the devstring types
    """
    letters = string.ascii_lowercase
    return "".join(random.choice(letters) for i in range(len))


def table_name(type, format):
    """
    Build the table name  from the type and format
    """
    return "att_" + format_types[format] + "_" + types[type]


def store_attribute_query():
    """
    Query to store an attribute in the database, returns the id so data can be added
    """
    query = (
        "INSERT INTO att_conf "
        + "(att_name, att_conf_type_id, att_conf_format_id, att_conf_write_id, table_name, cs_name, domain, family, member, name, hide, ttl)"
        + "(SELECT %s,att_conf_type_id,att_conf_format_id,att_conf_write_id,%s,%s,%s,%s,%s,%s,%s,%s "
        + "FROM att_conf_type, att_conf_format, att_conf_write "
        + "WHERE att_conf_type.type_num = %s AND att_conf_format.format_num = %s AND att_conf_write.write_num = %s) "
        + "RETURNING att_conf_id"
    )

    return query


def store_data_query(type, format, write):
    """
    Query to store data in the database, using a given id from the store attribute query
    """
    query = (
        "INSERT INTO "
        + table_name(type, format)
        + " (att_conf_id, data_time"
        + ",value_r, value_w"
        + ",quality) VALUES (%s,%s,%s,%s,%s)"
    )

    return query


def store_data_error_query(table_name):
    """
    Query to store some error data in the database
    """
    query = (
        "INSERT INTO "
        + table_name
        + " (att_conf_id, data_time,quality) VALUES (%s,TO_TIMESTAMP(%s),%s)"
    )

    return query


def select_att_conf_query():
    """
    Query to select all attributes in the att conf table    
    """
    query = (
        "SELECT att_conf_id, " \
            "(SELECT type FROM att_conf_type WHERE att_conf_type_id = a.att_conf_type_id), " \
            "(SELECT format FROM att_conf_format WHERE att_conf_format_id = a.att_conf_format_id), " \
            "(SELECT write FROM att_conf_write WHERE att_conf_write_id = a.att_conf_write_id) FROM att_conf a"
    )

    return query


def no_data(type, data_requested):
    """
    Return a None, no data generated and stored for this value
    """
    return None


def data(type, data_requested):
    """
    Create noddy random data for each type
    """
    result = []

    for _ in range(data_requested):

        # this is crude but works, switch on the type (by given value) and
        # generate some data, then append this to the list
        if type is 1:
            result.append(random.choice([True, False]))

        elif type is 2:
            result.append(randint(-10000, 10000))

        elif type is 3:
            result.append(randint(-10000, 10000))

        elif type is 4:
            result.append(random.random())

        elif type is 5:
            result.append(round(random.random(), 2))

        elif type is 6:
            result.append(randint(0, 10000))

        elif type is 7:
            result.append(randint(0, 10000))

        elif type is 8:
            result.append(random_string(20))

        elif type is 19:
            result.append(randint(0, 10))

        elif type is 22:
            result.append(random.getrandbits(8))

        elif type is 23:
            result.append(randint(-10000, 10000))

        elif type is 24:
            result.append(randint(0, 10000))

        elif type is 28:
            raise Exception("Unsupported type - Encoded")

        elif type is 9:
            raise Exception("Unsupported type - Enum")

    # for a scalar, the requested number is 1, so return the actual value
    # to be stored in te data tables, in the case of an array the list is returned
    # since the data table requires an array
    if data_requested is 1:

        # return the element (scalar storage)
        return result[0]

    # return the list (array storage)
    return result


def insert_events(cursor, att_id, type, format, write, num_data, span):
    """
    Insert an event for an attribute
    """
    start_time = datetime.now() - timedelta(days=span)
    increment = timedelta(days=span) / num_data
    insert_events(cursor, att_id, type, format, write, num_data, span, start_time)

def insert_events(cursor, att_id, type, format, write, num_data, span, timestamp, increment):
    """
    Insert an event for an attribute
    """
    data_requested = 1

    # for array data, the array is randomly sized for each entry between 2
    # and 1024
    if format is 1:
        data_requested = randint(2, 1024)

    # each value initially raised no data, we then check below for the
    # write type, and if required, assign the data generator
    value_r = no_data
    value_w = no_data

    if write is 0 or write is 1:
        value_r = data

    if write is 2 or write is 3:
        value_w = data

    for _ in range(num_data):

        # store the data
        cursor.execute(store_data_query(type, format, write),
                       (att_id, timestamp, value_r(type, data_requested), value_w(type, data_requested), 1))

        timestamp = timestamp + increment


def generate_attributes(connection, num_attrs, num_data, type, format, write, span, ttl):
    """
    Generate an attribute and its data for the given type info. The number of times the
    attribute is created is multiplied by num_attrs, and each generated attribute creates
    num_data data entries
    """

    # because we have to have this...
    cs_name = "localhost:10000"

    for _ in range(num_attrs):
        domain = random_string(10)
        family = random_string(10)
        member = random_string(10)
        name = random_string(10)
        fqdn_attr_name = "tango://" + cs_name + "/" + domain + "/" + family + "/" + member + "/" + name

        cursor = connection.cursor()

        if verbose:
            print("Inserting attribute: {} with traits: {}/{}/{}".format(fqdn_attr_name, type, format, write))

        # insert the new attribute
        cursor.execute(store_attribute_query(),
                       (fqdn_attr_name, table_name(type, format), cs_name, domain, family, member, name, False, int(ttl) * 24, type, format, write))

        # fetch the id created for the attribute, this will be used in the data table
        att_id = cursor.fetchone()[0]

        if verbose:
            print("Inserting {} data items for attribute: {}".format(num_data, fqdn_attr_name))

        insert_events(cursor, att_id, type, format, write, num_data, span)

        connection.commit()
        cursor.close()


def order_chunks(connection, table_name, span):
    """
    Having filled the table we data, we order the chunks for optimal query speed
    """

    cursor = connection.cursor()

    if verbose:
        print("Fetching the last '{}' days of chunks for table {}".format(span, table_name))

    # ensure we are clustering on the composite index
    cursor.execute("ALTER TABLE {} CLUSTER ON {}{};".format(table_name, table_name, idx_postfix))

    # get the config window of chunks to be reordered
    cursor.execute("SELECT show_chunks('{}', newer_than => interval '{}');".format(table_name, span))
    chunks = cursor.fetchall()

    if verbose:
        print("Fetched {} chunk(s)".format(len(chunks)))

    for chunk in chunks:

        # do the actual reorder of the chunk
        cursor.execute("SELECT reorder_chunk('{}', index => '{}{}');".format(chunk[0], table_name, idx_postfix))

    if verbose:
        print("Reordered chunks for {}".format(table_name))

    connection.commit()
    cursor.close()


def truncate_tables(connection):
    """
    Truncate the table
    """

    cursor = connection.cursor()
    cursor.execute("TRUNCATE att_conf RESTART IDENTITY CASCADE")
    connection.commit()
    cursor.close()


def run_new_db_command(args):
    """
    Handler for argparse
    """

    # first attempt to open a connection to the database
    try:
        if verbose:
            print("Attempting to connect to server. Connect: {}".format(args.connect))

        # attempt to connect to the server
        connection = psycopg2.connect(args.connect)
        connection.autocommit = True

        if verbose:
            print("Connected to database at server")

    except (Exception, psycopg2.Error) as error:
        print("Error: {}".format(error))
        return False

    if args.truncate:
        if verbose:
            print("Truncating all tables")

        truncate_tables(connection)

    # create random data for each type/format/write
    for type in type_numbers:
        for format in format_numbers:
            for write in write_numbers:
                name = table_name(type, format)

                if verbose:
                    print("Generating for combination {}/{}/{} in table {}".format(type, format, write, name))

                generate_attributes(connection, args.num_attr, args.num_data, type, format, write, args.span, args.ttl)

            if verbose:
                print("Ordering data in table: {}".format(name))

            order_chunks(connection, name, args.span)

    return True


def run_data_command(args):
    """
    Handler for argparse
    """

    # first attempt to open a connection to the database
    try:
        if verbose:
            print("Attempting to connect to server. Connect: {}".format(args.connect))

        # attempt to connect to the server
        connection = psycopg2.connect(args.connect)
        connection.autocommit = False

        if verbose:
            print("Connected to database at server")

    except (Exception, psycopg2.Error) as error:
        print("Error: {}".format(error))
        return False

    # grab all the existing attributes
    cursor = connection.cursor()

    if verbose:
        print("Fetching attributes")

    cursor.execute(select_att_conf_query())
    attributes = cursor.fetchall()

    if verbose:
        print("Fetched {} attributes(s)".format(len(attributes)))

    count = 0

    # when infinite, must be ctrl-c to kill
    while args.events == 0 or count < args.events:

        if verbose:
            print("Generating event data")

        start_time = datetime.now() - timedelta(days=0)
        increment = timedelta(days=0)

        # insert some data for each attribute
        for attribute in attributes:
            insert_events(cursor, attribute[0], db_types[attribute[1]], db_formats[attribute[2]], db_write[attribute[3]], 1, 0, start_time, increment)

        time.sleep(args.interval)

        count = count + 1
        connection.commit()

    connection.commit()
    cursor.close()

    return True

def main():
    parser = argparse.ArgumentParser(description="Create and simulate random test data in the hdb database")
    parser.add_argument("-v", "--verbose", action="store_true", help="verbose execution")

    parser.add_argument(
        "-c",
        "--connect",
        metavar="STR",
        default="user=postgres host=localhost port=5432 password=password dbname=hdb",
        help="connect string (default user=postgres password=password host=localhost port=5432 dbname=hdb)"
    )

    subparsers = parser.add_subparsers(title="available commands", metavar="mode")

    parser_new_db = subparsers.add_parser("db", help="create/load random data into the database")
    parser_new_db.add_argument("--num-attr", metavar="NUM", default=100, type=int, help="number of attributes to insert per type (default 100)")
    parser_new_db.add_argument("--num-data", metavar="NUM", default=100, type=int, help="number of data items to insert per attribute (default 100)")
    parser_new_db.add_argument("--span", metavar="DAYS", default=0, type=int, help="number of days in the past to spread the events over (default 1)")
    parser_new_db.add_argument("--ttl", metavar="DAYS", default=0, help="ttl to give the data")
    parser_new_db.add_argument("--truncate", action="store_true", help="truncate all tables first")
    parser_new_db.set_defaults(func=run_new_db_command)

    parser_data = subparsers.add_parser("data", help="write data to the database at intervals")
    parser_data.add_argument("--interval", metavar="SECONDS", default=5, type=float, help="write data to the database every x seconds (default 5)")
    parser_data.add_argument("--events", metavar="NUM", default=0, type=int, help="number of events, 0 for infinite (default 0)")
    parser_data.set_defaults(func=run_data_command)

    args = parser.parse_args()

    global verbose
    verbose = args.verbose

    return args.func(args)


if __name__ == "__main__":
    result = main()

    if result is not True:
        print("Command failed\n")
