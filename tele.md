# VTK Build and Installation Guide

Follow these step-by-step instructions to clone, configure, build, and install VTK with Qt6 support.

## Step 1: Clone VTK Source


```bash
# Create directory and navigate into it
mkdir -p ~/vtk
cd ~/vtk
git clone [https://github.com/Kitware/VTK.git](https://github.com/Kitware/VTK.git) source

##Step 2: Create Build Directory

Bash
cd ~/vtk
mkdir build
cd build

##Step 3: Configure VTK with Qt6

⚠️ IMPORTANT: Replace <YOUR_USERNAME> with your actual Linux system username. Also, double-check that the version number (6.10.3) matches your specific Qt path.

Bash
cmake ../source \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=/home/<YOUR_USERNAME>/Qt/6.10.3/gcc_64 \
  -DQt6_DIR=/home/<YOUR_USERNAME>/Qt/6.10.3/gcc_64/lib/cmake/Qt6 \
  -DVTK_GROUP_ENABLE_Qt=YES \
  -DVTK_MODULE_ENABLE_VTK_GUISupportQt=YES \
  -DVTK_MODULE_ENABLE_VTK_RenderingQt=YES \
  -DVTK_QT_VERSION=6


##Step 4: Verify Qt6 Detection

Bash
grep "Qt[56]" CMakeCache.txt

##Step 5: Build VTK

Bash
make -j2

##Step 6: Install VTK
Bash
sudo make install
