#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import getopt
import sys
import os
import threading

NAME = os.path.basename(__file__)

### VARS ###
in_links_filepath = ""
destinyDirectory = ""
### VARS  ###




def print_help():
    print NAME + " --origin </home/User/onetab_links.txt> [--destiny </home/User/>]"
    print "         -i | --links:   - Required : The absolute path to parse the export of the onetab links."
    print "         -o | --mardown: - Optional : The absolute path to write the markdowns links."
    sys.exit(0)


################################################################
# AUX FUNCs
################################################################

# Print iterations progress
# https://stackoverflow.com/a/34325723/8091456
# https://gist.github.com/aubricus/f91fb55dc6ba5557fbab06119420dd6a
def print_progress(iteration, total, prefix='', suffix='', decimals=1, bar_length=100, fill='█'):
    """
    Call in a loop to create terminal progress bar
    @params:
        iteration   - Required  : current iteration (Int)
        total       - Required  : total iterations (Int)
        prefix      - Optional  : prefix string (Str)
        suffix      - Optional  : suffix string (Str)
        decimals    - Optional  : positive number of decimals in percent complete (Int)
        bar_length  - Optional  : character length of bar (Int)
    """
    str_format = "{0:." + str(decimals) + "f}"
    percents = str_format.format(100 * (iteration / float(total)))
    filled_length = int(round(bar_length * iteration / float(total)))
    bar = fill * filled_length + '-' * (bar_length - filled_length)

    sys.stdout.write('\r%s |%s| %s%s %s' %
                     (prefix, bar, percents, '%', suffix)),

    if iteration == total:
        sys.stdout.write('\n')
    sys.stdout.flush()



################################################################
# AUX FUNCs
################################################################



class process_link_thread(threading.Thread):
    def __init__(self, line):
        threading.Thread.__init__(self)
        self.line = line

    def run(self):
        global mLinks
        temp = self.line.split(" | ")
        url = temp[0]
        desc = temp[1]
        mLink = "["+desc+"]"+"("+url+")\n"
        mLinks.append(mLink)



def getMardownkLinks_from_onetabLinksFile(in_links_filepath):

    threads_array = list()

    lines = [line.rstrip('\n') for line in open(in_links_filepath)]

    for l in lines:
        if l != "":
            th = process_link_thread(l)
            threads_array.append(th)
            th.start()

    nThreads_array = len(threads_array)
    print_progress(0, nThreads_array, prefix='Progress:',
               suffix='Complete', bar_length=50)
    # Wait for all threads
    for idth, th in enumerate(threads_array):
        print_progress(idth+1, nThreads_array, prefix='Progress:',
                    suffix='Complete', bar_length=50)
        th.join()

    return mLinks


def main(argv):

    global mLinks

    in_links_filepath = ""
    out_links_filepath = ""

    try:
        opts, args = getopt.getopt(argv,"i:o:h",["links=","mardown=","help"])
    except getopt.GetoptError:
      print_help()
      sys.exit(-1)
    for opt, arg in opts:
        if opt in ("-i", "--links"):
            folderpath = os.path.abspath(arg)
            if os.path.isfile(folderpath):
                in_links_filepath = folderpath
                out_links_filepath = folderpath+".md"
            else:
                print "Origin path not valid: " + folderpath
                sys.exit(-1)
        elif opt in ("-o", "--mardown"):
            folderpath = os.path.abspath(arg)
            if folderpath != "":
                out_links_filepath = folderpath+".md"
        elif opt in ("-h", "--help"):
            print_help()
        else:
            print "arg not valid"


    mLinks = list()
    mardownkLinks = getMardownkLinks_from_onetabLinksFile(in_links_filepath)



    with open(out_links_filepath, 'w') as f:
        for l in mardownkLinks:
            f.write("%s\n" % l)



if __name__ == "__main__":
    main(sys.argv[1:])
