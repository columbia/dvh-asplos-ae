#!/usr/bin/python

import numpy as np
import os
import sys

def print_result_test(path, testname):
	data = np.array([])

	for root, dirs, files in os.walk(path):
		for dirname in sorted(dirs, key=int):
			filename = path + "/" + dirname + "/" + testname + ".txt"

#			if dirname == "7":
#				break

			if (testname in has_header_2):
				new_data = np.loadtxt(filename, skiprows=2)
			elif (testname in has_header):
				new_data = np.loadtxt(filename, skiprows=1)
			else:
				new_data = np.loadtxt(filename)

			try:
				iterations = new_data.shape[0]
			except IndexError:
				print ("%s %s index error. Skip." % (testname, dirname))
				return

			new_data.shape = (iterations, 1)

			if data.size == 0:
				data = new_data
			else:
				if iterations != data.shape[0]:
					print ("%s %s has %d iterations while it is supposed to have %d. Skip." % (testname, dirname, iterations, data.shape[0]))
					continue

				try:
					data = np.concatenate((data, new_data), axis=1)
				except ValueError:
					print ("%s %s value error. Skip." % (testname, dirname))
					continue

	print ("----------" + testname + "----------")
	print ('\n'.join(','.join(str(cell) for cell in row) for row in data))
	print ("------------------------------------------------------------")
	print ("")

def probe_test_names(path):

	test_name_list = []
	for root, dirs, files in os.walk(path + "/1"):
		for file in files:
			testname = file.rsplit(".", 1)[0]
			if testname != "":
				test_name_list.append(testname)

	return test_name_list

if len(sys.argv) < 2:
	print ("Usage: ./results.py <dirname> [testname]")
	sys.exit(1)

#Add test names if it has a header in the result text file
has_header = ["memcached", "netperf-rr", "netperf-stream", "netperf-maerts"]
has_header_2 = ["mysql"]
path = sys.argv[1]

if (len(sys.argv) > 2):
	testname = sys.argv[2]
	test_name_list = []
	test_name_list.append(testname)
else:
	test_name_list = probe_test_names(path)

for test in test_name_list:
	print test
	print_result_test(path, test)

