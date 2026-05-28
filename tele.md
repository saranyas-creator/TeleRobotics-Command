# VTK Build and Installation Guide

Follow these step-by-step instructions to clone, configure, build, and install VTK with Qt6 support.

## Step 1: Clone VTK Source
Create a dedicated folder in your home directory and clone the official VTK source code repository.

```bash
# Create directory and navigate into it
mkdir -p ~/vtk
cd ~/vtk

# Clone the repository into a folder named 'source'
git clone [https://github.com/Kitware/VTK.git](https://github.com/Kitware/VTK.git) source
Step 2: Create Build Directory
Always separate the build files from the source files. Create an isolated build folder.

Bash
cd ~/vtk

mkdir build
cd build
Step 3: Configure VTK with Qt6
Use CMake to generate the build files. This step explicitly points VTK to your local Qt6 installation and enables necessary UI rendering modules.

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
Step 4: Verify Qt6 Detection
Check the generated configuration cache to ensure that CMake has picked up the correct Qt6 libraries and hasn't fallback-targeted any remnants of older Qt versions.

Bash
grep "Qt[56]" CMakeCache.txt
Step 5: Build VTK
Compile the software from source. We limit this process to 2 parallel jobs to manage memory and prevent compilation crashes on machines with constrained hardware.

Bash
make -j2
Step 6: Install VTK
Once compiled successfully, install the libraries globally on your operating system so your Qt Creator projects can dynamically link against them.

Bash
sudo make install
