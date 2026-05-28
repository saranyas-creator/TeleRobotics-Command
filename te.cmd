#VTK INSTALLATION

# STEP 1: Clone VTK Source
# ============================================================
echo "------------------------------------------------"
echo "Step 1: Creating directory and cloning VTK..."
echo "------------------------------------------------"
mkdir -p ~/vtk
cd ~/vtk
git clone https://github.com/Kitware/VTK.git source

# ============================================================
# STEP 2: Create Build Directory
# ============================================================
echo "------------------------------------------------"
echo "Step 2: Creating clean build directory..."
echo "------------------------------------------------"
cd ~/vtk
mkdir -p build
cd build

# ============================================================
# STEP 3: Configure VTK with Qt6
# ============================================================
echo "------------------------------------------------"
echo "Step 3: Configuring VTK with CMake flags..."
echo "------------------------------------------------"
# NOTE: Replace <YOUR_USERNAME> with your actual Linux username
cmake ../source \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=/home/<YOUR_USERNAME>/Qt/6.10.3/gcc_64 \
  -DQt6_DIR=/home/<YOUR_USERNAME>/Qt/6.10.3/gcc_64/lib/cmake/Qt6 \
  -DVTK_GROUP_ENABLE_Qt=YES \
  -DVTK_MODULE_ENABLE_VTK_GUISupportQt=YES \
  -DVTK_MODULE_ENABLE_VTK_RenderingQt=YES \
  -DVTK_QT_VERSION=6

# ============================================================
# STEP 4: Verify Qt6 Detection
# ============================================================
echo "------------------------------------------------"
echo "Step 4: Checking CMakeCache for Qt configurations..."
echo "------------------------------------------------"
grep "Qt[56]" CMakeCache.txt

# ============================================================
# STEP 5: Build VTK
# ============================================================
echo "------------------------------------------------"
echo "Step 5: Compiling VTK source code (using 2 cores)..."
echo "------------------------------------------------"
make -j2

# ============================================================
# STEP 6: Install VTK
# ============================================================
echo "------------------------------------------------"
echo "Step 6: Installing VTK libraries system-wide..."
echo "------------------------------------------------"
sudo make install

echo "================================================"
echo "VTK Installation Process Completed Successfully!"
echo "================================================"
