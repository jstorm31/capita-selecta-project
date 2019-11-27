#! /bin/bash

rm jmeter_order.log;
rm -r out;
jmeter -n -t order.jmx -l jmeter_order.log -e -o out;
