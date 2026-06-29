// in Windows, you must define an initialization function for your extension
// because setuptools will build a .pyd file, not a DLL
// https://stackoverflow.com/questions/34689210/error-exporting-symbol-when-building-python-c-extension-in-windows

#include "qmctoolscl.h"

#include <Python.h>

PyMODINIT_FUNC PyInit_c_lib(void)
{
    // do stuff...
    printf("");
}