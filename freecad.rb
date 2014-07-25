require "formula"

class Freecad < Formula
  homepage "http://sourceforge.net/projects/free-cad/"
  head "https://github.com/mangtronix/FreeCAD_mangtronix.git"
  version '0.14-HEAD'

  # Debugging Support
  option 'with-debug', 'Enable debugging build'

  # Should work with OCE (OpenCascade Community Edition) or Open Cascade
  # OCE is the prefered option
  option 'with-opencascade', 'Build with OpenCascade'
  if build.with? 'opencascade'
    depends_on 'opencascade'
  else
    depends_on 'oce'
  end

  # Build dependencies
  depends_on 'doxygen' => :build
  depends_on 'cmake' => :build
  depends_on 'swig' => :build
  depends_on :fortran => :build

  # Required dependencies
  depends_on 'boost'
  depends_on 'sip'
  depends_on 'xerces-c'
  depends_on 'eigen'
  depends_on 'coin'
  depends_on 'qt'
  depends_on 'pyqt'
  depends_on 'shiboken'
  depends_on 'pyside'
  #depends_on :python
  # Currently depends on custom build of python 2.7.6
  # see: http://bugs.python.org/issue10910 
  depends_on 'python'

  # Recommended dependencies
  depends_on 'freetype' => :recommended

  # Optional Dependencies
  depends_on :x11 => :optional

  def install
    if build.with? 'debug'
      ohai "Creating debugging build..."
    end

    # Enable Fortran
    libgfortran = `$FC --print-file-name libgfortran.a`.chomp
    ENV.append 'LDFLAGS', "-L#{File.dirname libgfortran} -lgfortran"
    inreplace "CMakeLists.txt", "if(CMAKE_COMPILER_IS_GNUCXX)\nENABLE_LANGUAGE(Fortran)\nendif(CMAKE_COMPILER_IS_GNUCXX)", 'ENABLE_LANGUAGE(Fortran)'

    # Brewed python include and lib info
    # TODO: Don't hardcode bin path
    python_prefix = `/usr/local/bin/python-config --prefix`.strip
    python_library = "#{python_prefix}/Python"
    python_include_dir = "#{python_prefix}/Headers"

    # Find OCE cmake file location
    # TODO add opencascade support/detection
    oce_dir = "#{Formula['oce'].opt_prefix}/OCE.framework/Versions/#{Formula['oce'].version}/Resources"

    # Set up needed cmake args
    args = std_cmake_args + %W[
      -DFREECAD_BUILD_ROBOT=OFF
      -DPYTHON_LIBRARY=#{python_library}
      -DPYTHON_INCLUDE_DIR=#{python_include_dir}
      -DOCE_DIR=#{oce_dir}
      -DFREETYPE_INCLUDE_DIRS=#{Formula.factory('freetype').opt_prefix}/include/freetype2/
    ]

    if build.with? 'debug'
      # Create debugging build and tack on the build directory
      args << '-DCMAKE_BUILD_TYPE=Debug' << '.'
    
      system "cmake", *args
      system "make", "install"
    else
      # Create standard build and tack on the build directory
      args << '.'
    
      system "cmake", *args
      system "make", "install/strip"
    end
  end

  def caveats; <<-EOS.undent
    After installing FreeCAD you may want to do the following:

    1. Amend your PYTHONPATH environmental variable to point to
       the FreeCAD directory
         export PYTHONPATH=#{bin}:$PYTHONPATH
    EOS
  end
end
