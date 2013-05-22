/**
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>. 
**/

package main

import (
    "fmt"
    "strings"
    "io/ioutil"
    "path/filepath"
    "bytes"
    "os"
    "syscall"
)

func main() {
    Stderr := os.NewFile(uintptr(syscall.Stderr), "stderr")
    
    path := "/"
    debug := true
	statistics := 0
	// * 0 none
	// * 1 only
	// * 2 additional
    
    //Parse command line arguments
    args := os.Args
    for i := 0; i < len(args); i++ {
        if args[i] == "-d" || args[i] == "--directory" {
            if (i+1) == len(args) {
                Stderr.WriteString("Error!\n")
                Stderr.WriteString("Please specify a directory path!\n\n\n")
                printHelp()
                return
            } else {
                path = args[i+1]
            }
        } else if args[i] == "-h" || args[i] == "--help" {
            printHelp()
            return
        } else if args[i] == "-q" || args[i] == "--quiet" {
            //don't print errors (stderr), but print normal output (stdout)
            debug = false
        } else if args[i] == "-s" || args[i] == "--statistics" {
            if (i+1) == len(args) {
                Stderr.WriteString("Error!\n")
                Stderr.WriteString("Please specify a value for statistics option!\n")
                Stderr.WriteString("Possible values are: none, only, additional\n\n")
                printHelp()
                return;
            } else {
                switch (args[i+1]) {
                    default:
                        Stderr.WriteString("Error!\n")
                        Stderr.WriteString("Please specify a value for statistics option!\n")
                        Stderr.WriteString("Possible values are: none, only, additional\n\n")
                        printHelp()
                        return;
                    case "none":
                        statistics = 0
                    case "only":
                        statistics = 1
                    case "additional":
                        statistics = 2
                }
            }
        } 
    }
    
    //Start execution
    dirCount := 0
    fileCount := 0
    var buf bytes.Buffer
    
    scanDirectory(path, &buf, &dirCount, &fileCount, &debug)
    
    switch (statistics) {
        case 0:
            fmt.Println(buf.String())
        case 1:
            fmt.Printf("\nFiles: %d\n", fileCount)
            fmt.Printf("Directories: %d\n", dirCount)
        case 2:
            fmt.Println(buf.String())
            fmt.Printf("\nFiles: %d\n", fileCount)
            fmt.Printf("Directories: %d\n", dirCount)
    }
}

func printHelp() {
    fmt.Printf("\nThis program will scan a filesystem hierarchy and print it in a machine-readable\nformat.\n\n")
    
    fmt.Printf("All files will be listed in one line seperated by commas (commas in filenames\nwill be escaped). Directories will be displayed as foldername with their\ncontents in brackets after them. (brackets in filenames will be escaped)\n")
    fmt.Printf("\nFor example:\n")
    fmt.Printf("topfolder1(file1,file2,subfolder(sub1,sub2),file3),topfolder2(folder())\n\n")
    
    fmt.Printf("Though this program does not support writing its output to a file it is\nperfectly safe to redirect all its output (stdout, not stderr) to a file.\n")
    fmt.Printf("On most systems you can do this by calling the program like:\n")
    fmt.Printf("\tfsdump -d /usr -s none > output.txt\n")
    
    fmt.Printf("\n\nOptions:\n")
    
    fmt.Printf("  -d, --directory\tThe directory to start scanning at, fsdump will\n")
    fmt.Printf("  \t\t\tcontinue to scan directories recursively.\n")
    fmt.Printf("  \t\t\tIf you don't have the required rights to read a\n")
    fmt.Printf("  \t\t\tdirectory, fsdump will print an error and go on.\n")
    fmt.Printf("  \t\t\tIf -d is not given fsdump will assume / as a path.\n")
    
    fmt.Printf("  -h, --help\t\tPrint this help and exit\n")
    fmt.Printf("  \t\t\tNote: this will not be influenced by -q\n")
    
    fmt.Printf("  -q, --quiet\t\tDon't print errors (for example if a directory could\n")
    fmt.Printf("  \t\t\tnot be searched because you do not have the required\n")
    fmt.Printf("  \t\t\tpermission)\n")
    fmt.Printf("  \t\t\tBut of course this will still print normal file\n")
    fmt.Printf("  \t\t\tsystem hierarchy.\n")
    fmt.Printf("  \t\t\tDefault is to print errors (to stderr).\n")
    fmt.Printf("  \t\t\tNote: This will not influence -h / --help\n")
    
    fmt.Printf("  -s, --statistics\tWhether (and how) to print statistics.\n")
    fmt.Printf("  \t\t\tTheses statistics consist of:\n")
    fmt.Printf("  \t\t\t- Number of files\n")
    fmt.Printf("  \t\t\t- Number of directories\n")
    fmt.Printf("  \t\t\tInternally these statistics get created anyway so there\n")
    fmt.Printf("  \t\t\tshould be no speed difference.\n")
    fmt.Printf("  \t\t\tPossible values:\n")
    fmt.Printf("  \t\t\t- none [DEFAULT]\n")
    fmt.Printf("  \t\t\t  Don't print statistics. (only filesystem hierarchy)\n")
    fmt.Printf("  \t\t\t- only\n")
    fmt.Printf("  \t\t\t  Print only statistics and no filesystem hierarchy.\n")
    fmt.Printf("  \t\t\t- additional\n")
    fmt.Printf("  \t\t\t  Print filesystem hierarchy and on line two and three\n")
    fmt.Printf("  \t\t\tprint statistics. (This might not be easy to parse...)\n")
    
}

func escape(str string) string {
    str = strings.Replace(str, ",", "\\,", -1)
    str = strings.Replace(str, ")", "\\)", -1)
    str = strings.Replace(str, "(", "\\(", -1)
    return str
}

func scanDirectory(path string, buffer *bytes.Buffer, dirCount *int, fileCount *int, debug *bool) {
    putComma := false
    subDirectories, directoryError := ioutil.ReadDir(path)
    
    if (directoryError != nil) {
        if (*debug) {
            Stderr := os.NewFile(uintptr(syscall.Stderr), "stderr")
            Stderr.WriteString("\nError while iterating over directorys\n")
            Stderr.WriteString(directoryError.Error()+"\n")
        }
    }
    
    for _, element := range subDirectories {
        if !element.IsDir() {
            if (putComma) {
                buffer.WriteString(",")
            } else {
                putComma = true
            }
            
            buffer.WriteString(escape(element.Name()))
            *fileCount++
        } else {
            if (putComma) {
                buffer.WriteString(",")
            } else {
                putComma = true
            }
            
            buffer.WriteString(escape(filepath.Base(element.Name()))+"(")
            if !strings.HasSuffix(path, "/") {
                scanDirectory(path+"/"+element.Name(), buffer, dirCount, fileCount, debug)
            } else {
                scanDirectory(path+element.Name(), buffer, dirCount, fileCount, debug)
            }
            buffer.WriteString(")")
            *dirCount++
        }
    }
}
