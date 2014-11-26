#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys
import os 
import re
import json
os.chdir(os.path.dirname ( sys.argv[0] ) )

def do_func(ac_prefix):
    import function_data 
    ac_prefix_len= len(ac_prefix);
    ret_list=[]
    for item  in function_data.function_data:
        key_word=item[1];
        #print key_word
        key_fix=key_word[:ac_prefix_len] 
        if  (key_fix> ac_prefix ) :
            break;

        if  (key_fix == ac_prefix ) :
            ret_list.append(item)
            pass
    print json.dumps(ret_list);

def do_get_func( func_name):
    import function_data 
    ret_list=[]
    for item  in function_data.function_data:
        key_word=item[1];
        if  (key_word== func_name) :
            ret_list.append(item)
            pass
    print json.dumps(ret_list);



def do_class(class_name ):
    import class_data 
    if class_data.class_data.has_key(class_name):
        print json.dumps(class_data.class_data[class_name] );
    else:
        print json.dumps([]);

def do_class_member(class_name,member ):
    import class_data 
    ret_list=[]
    if class_data.class_data.has_key(class_name):
        class_item= class_data.class_data[class_name];
        for member_info in class_item:
            if (member_info[1] == member):
                ret_list.append(member_info);
                
    print json.dumps(ret_list);
def get_class_member_type(class_data, class_name,member ):
    ret_list=[]
    if class_data.has_key(class_name):
        class_item= class_data[class_name];
        for member_info in class_item:
            if (member_info[1] == member):
                return member_info[5]

    return ""

def get_class_name( key_str ):
    """
    """
    import class_data 
    arr=key_str.split('.')
    arr=arr[:-1]
    cur_class=""
    for item in arr:
        if cur_class=="":
            cur_class=item
        else:
            cur_class=get_class_member_type(class_data.class_data,cur_class,item )
            if cur_class=="":
                return "" 
    return cur_class

import optparse


p = optparse.OptionParser(
    description=' hex --> int ',
    prog='cint',
    version='cint 0.1',
    usage='%prog [-b] F0 01 00 00 ' )
p.add_option('-f', '--list-function',  help='' )
p.add_option('-c', '--list-class-member',  help='' )
p.add_option('-F', '--find-function', help='' )
p.add_option('-C', '--find-class-member',  help='' )

options, arguments = p.parse_args()	

if options.list_function:
    do_func(options.list_function)
if options.list_class_member:
    class_name=get_class_name( options.list_class_member )
    do_class(class_name)

if options.find_class_member:
    class_name=get_class_name( options.find_class_member )
    do_class_member(class_name, options.find_class_member. split(".")[-1]  )

if options.find_function:
    do_get_func(options.find_function)


