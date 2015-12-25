from distutils.core import setup
from distutils.extension import Extension

from os import system

setup(name='vsimj4a',
  ext_modules=[ 
    Extension('vsimj4a',
              ['vsim4.cpp'],
              depends=["obj_dir/Vv3__ALL.a"],
              extra_objects=["obj_dir/verilated.o", "obj_dir/Vj4a__ALL.a"],
              include_dirs=["obj_dir",
                            "/usr/local/share/verilator/include/",
                            "/usr/share/verilator/include/",
                            "/usr/local/share/verilator/include/vltstd/",
                            "/usr/share/verilator/include/vltstd/"],
              extra_compile_args=['-O2'])
  ],
)
