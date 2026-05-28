# VTK Build and Installation Guide

Follow these step-by-step instructions to clone, configure, build, and install VTK with Qt6 support.

---

# Step 1: Clone VTK Source


```bash
# Create directory and navigate into it
mkdir -p ~/vtk
cd ~/vtk

# Clone the repository into a folder named 'source'
git clone https://github.com/Kitware/VTK.git source
```

---

# Step 2: Create Build Directory

Always separate the build files from the source files. Create an isolated build folder.

```bash
cd ~/vtk

mkdir build
cd build
```

---

# Step 3: Configure VTK with Qt6

Use CMake to generate the build files. This step explicitly points VTK to your local Qt6 installation and enables the required Qt rendering modules.



```bash
cmake ../source \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=/home/<YOUR_USERNAME>/Qt/6.10.3/gcc_64 \
  -DQt6_DIR=/home/<YOUR_USERNAME>/Qt/6.10.3/gcc_64/lib/cmake/Qt6 \
  -DVTK_GROUP_ENABLE_Qt=YES \
  -DVTK_MODULE_ENABLE_VTK_GUISupportQt=YES \
  -DVTK_MODULE_ENABLE_VTK_RenderingQt=YES \
  -DVTK_QT_VERSION=6
```

---

# Step 4: Verify Qt6 Detection

Verify that CMake correctly detected Qt6 and that no Qt5 references are present.

```bash
grep "Qt[56]" CMakeCache.txt
```

Expected result:

* Only `Qt6` entries should appear.
* There should be no `Qt5` references.

---

# Step 5: Build VTK

Compile VTK from source.


```bash
make -j2
```

---

# Step 6: Install VTK



```bash
sudo make install
```

---

# Step 7: Verify Installation

Verify that `VTKConfig.cmake` was installed successfully.

```bash
find /usr/local -name "VTKConfig.cmake"
```

Example expected output:

```bash
/usr/local/lib/cmake/vtk-9.5/VTKConfig.cmake
```

---

# Step 8: Configure Your Qt Project

Inside your project's `CMakeLists.txt`, add:

```cmake
find_package(VTK REQUIRED COMPONENTS
    CommonCore
    CommonColor
    RenderingCore
    RenderingOpenGL2
    InteractionStyle
    FiltersSources
    GUISupportQt
)

target_link_libraries(TeleRobotics PRIVATE
    ${VTK_LIBRARIES}
)

vtk_module_autoinit(
    TARGETS TeleRobotics
    MODULES ${VTK_LIBRARIES}
)
```

---



