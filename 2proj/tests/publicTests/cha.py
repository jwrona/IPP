#! /usr/bin/env python3
# -*- coding: utf_8 -*-
#CHA:xwrona00

#####
#Author: Jan Wrona, xwrona00@stud.fit.vutbr.cz
#Project: C Header analysis
#Course: IPP
#####

import sys
import os
import re

#return codes
retcode = {'ok': 0, 'params': 1, 'infile': 2, 'outfile': 3}

##### definitions #####
def argumentParser(arguments):
    """Parse command line arguments.

    Using argparse library. Help must not be combined with other arguments.
    """
    import argparse

    #mutally exclusive '--help' hack
    if '--help' in sys.argv and len(sys.argv) != 2:
        sys.stderr.write('{}: --help cannot be combined with other arguments\n'.format(__file__))
        exit(retcode['params'])
    elif '--help' in sys.argv:
        print("""\
usage: cha.py [--help] | [ [--input=fileordir] [--output=filename]
              [--pretty-xml=k] [--no-inline] [--no-duplicates]
              [--remove-whitespace] [--max-par=n] ]
                                    
program analyse C header files (suffix .h) according to ISO C99 and
convert its function declarations into XML

optional arguments:
--help               show this help message and exit
--input=fileordir    input file or directory
--output=filename    output file or directory
--max-par=n          process only function with n or more parameters
--pretty-xml=k       pretty XML formatting, default k=4
--no-inline          skip inline functions
--no-duplicates      ignore duplicate declarations
--remove-whitespace  remove unnecessary whitespaces""")
        exit(retcode['ok'])

    class MyAction(argparse.Action):
        """Used as action when argument found.

        Passed as argument to argparse.ArgumentParser()."""
        count = 0

        def __call__(self, parser, namespace, values, option_string=None):
            """Contol unique occurence of argument.
            
            Write message to stderr and exit if argument not unique."""

            if self.count > 0:
                sys.stderr.write('{}: all arguments must be exclusive\n'.format(__file__))
                exit(retcode['params'])

            self.count += 1
            setattr(namespace, self.dest, values)

    #all arguments addition to parser
    parser = argparse.ArgumentParser(description='program is analysing C header\
                                     files (suffix .h) according to ISO C99', add_help=False)
    parser.add_argument('--input', action=MyAction, default='./', 
                        help='input file or directory')
    parser.add_argument('--output', action=MyAction,
                        help='output file or directory')
    parser.add_argument('--max-par', action=MyAction, help='process only function\
                        with N or more parameters', type=int, dest='maxpar')
    parser.add_argument('--pretty-xml', action=MyAction, nargs='?', type=int,
                        const=4, help='pretty XML formatting', metavar='N=4',
                        dest='pretty')

    parser.add_argument('--no-inline', action=MyAction, nargs=0, help='skip inline\
                        functions', dest='noinline')
    parser.add_argument('--no-duplicates', action=MyAction, nargs=0, help='ignore\
                        duplicate declarations', dest='noduplicates')
    parser.add_argument('--remove-whitespace', action=MyAction, nargs=0,
                        help='removes unnecessary whitespaces',
                        dest='removewhitespace')

    #argparse doesn't always return required return code
    try:
        args = parser.parse_args()
    except SystemExit:
        exit(retcode['params'])

    #saving arguments into global dictionary
    arguments['input'] = args.input
    arguments['output'] = args.output
    arguments['maxpar'] = args.maxpar
    arguments['pretty'] = args.pretty
    arguments['noinline'] = args.noinline
    arguments['nodup'] = args.noduplicates
    arguments['nows'] = args.removewhitespace

class HeaderFile:
    """Class for operations with whole file.


    Open, save into string, remove unnecessary parts: comments,
    macros and function bodies."""

    def __init__(self, name):
        """Create enpty string for content of file, call method read."""
        self.file = ''
        self.read(name);

    def read(self, name):
        '''Open file in read only mode, copy it to one string, close it.

        File name in argument name. Whole content is loaded into self.file.'''

        #safe file open, copy into string and close
        try:
            inFD = open(name, 'r')
            self.file = inFD.read()
            inFD.close()
        except IOError as err:
            sys.stderr.write('{}: {}\n'.format(__file__, err))
            exit(retcode['infile'])

    def strip(self):
        '''Removes comments and macros.

        Unable to process comments in string, comments in comments
        and strings in comments.
        Macros are removed, conditions are not proccesed.'''

        #ML comments, problem with: str = "/*" or // blah/*
        self.file = re.sub(r'/\*.*?\*/', ' ', self.file, flags=re.S)
        #SL comments, problem with: str = "//blah"
        self.file = re.sub(r'//.*', ' ', self.file)
        #Macros, single-line and multi-line
        self.file = re.sub(r'#(.*\\\n)*.*?\n', '', self.file)

    def removeBracesContent(self):
        '''Remove all text in curly braces.

        Braces are not removed, only content inside.'''

        brCount = 0
        tmpFile = ''

        #go through string
        for (i, w) in enumerate(self.file):
            #opening brace found
            if w == '{':
                tmpFile += '{'
                brCount += 1
            
            #if we are not inside any braces, append char into temporary string
            if brCount == 0:
                tmpFile += self.file[i]

            #closing brace fond
            if w == '}':
                tmpFile += '}'
                brCount -= 1

        self.file = tmpFile #teporary string into original string

    def findAllFunc(self):
        '''Find all functions declarations in file.

        Return list of two-tuples. Bacis parsing, split declaration
        into two strings: part before opening bracket and all arguments.
        int f1(double arg1, int*) will be ('int f1', 'double arg1, int*')'''

        return re.findall(r'\b([\w\s\*]*)\((.*?)\)\s*(?:;|{)', self.file,
                          re.DOTALL | re.MULTILINE)


def parseFile(absFilename, relFilename):
    """Parse every function declaratin and definition in file.

    Return list of instances of Function class."""

    inFile = HeaderFile(absFilename)

    inFile.strip()
    inFile.removeBracesContent()

    allFunc = inFile.findAllFunc()

    funcList = []
    for oneFunc in allFunc:
        func = Function(oneFunc, relFilename)

        if func.parse(): #parsing is successfull
            #parameter --no-duplicates
            duplicate = False
            if (arguments['nodup'] is not None):
                for dupFunc in funcList: #check all allready parsed functions for equality of name
                    if func.name == dupFunc.name:
                        duplicate = True
                        break

            if not duplicate:
                funcList.append(func)

    return funcList

class Function:
    """Operations with one (allready pre-parsed) function.

    Input is one element of tuple created by HeaderFile.fundAllFunc()
    and name of file, in which the function was. """

    def __init__(self, func, name):
        """Constuctor."""
        self.func = func
        self.file = name
        self.name = ''
        self.varargs = 'no'
        self.rettype = ''
        self.args = []

    def parse(self):
        """Call methods to parse function return value and arguments."""
        if not self.parseRetVal():
            return False

        if not self.parseArgs():
            return False

        return True

    def parseRetVal(self):
        """By regular expresion parse function return value and name.
        
        Affected by parameters --no-inline and --remove-whitespace."""

        match = re.match(r'(.*(?:\s|\*))(\w+)\b', self.func[0], re.DOTALL)
        if match is None: #not a function, probably a macro
            return False

        #parameter --no-inline
        if (arguments['noinline'] is not None) and (re.search('inline', match.group(1)) is not None):
            return False

        self.rettype = match.group(1).strip()
        self.name = match.group(2).strip()

        #parameter --remove-whitespace for function rettype
        if arguments['nows'] is not None:
            self.rettype = re.sub(r'\s*\*\s*', '*', self.rettype) #remove white-spaces around arterisk
            self.rettype = re.sub(r'\s+', ' ', self.rettype) #all white-space sequences into one space

        return True

    def parseArgs(self):
        """By regular expresions parse function arguments.
        
        Check for empty argument list, only void argument, 
        variable arguments count (...).
        Affected by --max-par=n and --remove-whitespace."""

        #match if empty parameters function f( )
        if re.match(r'^\s*$', self.func[1]) is not None:
            return True

        #match if no parameters function f(void)
        if re.match(r'^\s*void\s*$', self.func[1]) is not None:
            return True #pri max-par=0 by se tohle asi nemelo provest

        allArgs = re.split(',', self.func[1])
        argCount = 1 #argument counter, starting on 1
        for oneArg in allArgs:

            if re.match(r'^\s*(\.\.\.)\s*$', oneArg, re.DOTALL) is not None:
                self.varargs = 'yes'
                continue #nebo break? tri tecky by mely byt vzdykcy posledni argument

            #parameter --max-par=n
            if (arguments['maxpar'] is not None) and (argCount > arguments['maxpar']):
                return False

            match = re.match(r'(.*(?:\s|\*))(\w+)\b', oneArg, re.DOTALL)

            if match is None: #probably argument without name
                #sys.stderr.write('{}: {}() - {}\n'.format(__file__, self.name, 'wrong arguments'))
                pass
            else:
                self.args.append({'number': argCount, 'type': match.group(1).strip(),
                                  'name': match.group(2).strip()})
                #parameter --remove-whitespace for argument type
                if arguments['nows'] is not None:
                    self.args[-1]['type'] = re.sub(r'\s*\*\s*', '*', self.args[-1]['type']) #remove white-spaces around arterisk
                    self.args[-1]['type'] = re.sub(r'\s+', ' ', self.args[-1]['type']) #all white-space sequences into one space

            argCount += 1 #successfull argument parsing, incement argument counter

        return True
                
def generateXml(allFunc):
    """Return string containing not-formated XML.
    
    Input is list of lists containing allready parsed functions.
    Using xml.etree.ElementrTree. Some symbols are escapized."""

    from xml.etree.ElementTree import Element, SubElement, ElementTree
    from xml.etree import ElementTree
    
    #root element
    if os.path.isfile(arguments['input']):
        elemRoot = Element('functions', {'dir':''}) #input is file
    else:
        elemRoot = Element('functions', {'dir':arguments['input']}) #input is directory

    for funcPerFile in allFunc: #through files
        for func in funcPerFile: #through functions
            #sub element for every function
            elemFunc = SubElement(elemRoot, 'function', {'file':func.file, 'name':func.name,
                                  'varargs':func.varargs, 'rettype': func.rettype})
            #sub sub element for every argument
            for arg in func.args:
                elemArg = SubElement(elemFunc, 'param', {'number':str(arg['number']), 'type':arg['type']})

    xmlStr = ElementTree.tostring(elemRoot, encoding="unicode")
    return '<?xml version="1.0" encoding="utf-8"?>' + xmlStr + '\n'

def prettifyXml(xmlStr, indCount, indChar = ' '):
    """Return string containing pretty formated XML.
    
    Does not escapize any characters.
    Input is valid XML string, indentation character and size of indentation."""

    from xml.dom import minidom

    xmlParsed = minidom.parseString(xmlStr) #parse string into minidom object
    xmlPretty = xmlParsed.toprettyxml(indChar * indCount) #generate pretty xml
    return re.sub(r'^<\?xml version="1.0" \?>', '<?xml version="1.0" encoding="utf-8"?>', xmlPretty)

##### end of declarations #####

#arguments parsing
arguments = {}
argumentParser(arguments)

allFunc = [] #list of lists of functions in all files

if not os.path.exists(arguments['input']): #input does not exist
    sys.stderr.write('{}: {}\n'.format(__file__, 'input file or directory does not exist'))
    exit(retcode['infile'])

if os.path.isfile(arguments['input']): #input is a file
    try:
        with open(arguments['input']): #is file readable?
            pass
    except IOError as err:
        sys.stderr.write('{}: {}\n'.format(__file__, err))
        exit(retcode['infile'])

    allFunc.append(parseFile(arguments['input'], arguments['input']))

elif os.path.isdir(arguments['input']): #input is a directory
    #go through all files in input directory and subdirectories
    #excluded are only '.' and '..' (hidden files are NOT excluded)
    for (dirpath, dirnames, filenames) in os.walk(arguments['input']):
        for filename in filenames:
            #create pseudo absolute path
            filename = os.path.join(dirpath, filename)
            #filter for non header files (without .h suffix)
            if re.match('^.*\.h$', filename) is not None:
                #create path relative to input path
                relativePath = os.path.relpath(filename, arguments['input'])
                allFunc.append(parseFile(filename, relativePath))

else: #input is not file nor directory
    sys.stderr.write('{}: {}\n'.format(__file__, 'input is not file nor directory'))
    exit(retcode['infile'])

#xml generating
xmlStr = generateXml(allFunc)
if arguments['pretty'] is not None:
    #indenting xml
    xmlStr = prettifyXml(xmlStr, arguments['pretty'])

#output
if arguments['output'] is None:
    print(xmlStr, end='') #to stderr
else:
    try:
        output = open(arguments['output'], 'w')
        output.write(xmlStr) #to specified output file
        output.close()
    except IOError as err:
        sys.stderr.write('{}: {}\n'.format(__file__, err))
        exit(retcode['outfile'])
