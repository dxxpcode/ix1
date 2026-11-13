cmake_minimum_required(VERSION 3.21)
project(ix1-software-center LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
qt_standard_project_setup()

qt_add_executable(ix1-software-center
    src/main.cpp
    src/backend.cpp
    src/backend.h
)

target_link_libraries(ix1-software-center PRIVATE Qt6::Quick)

set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(ix1-software-center
    URI Ix1SoftwareCenter
    VERSION 1.0
    QML_FILES
        qml/Theme.qml
        qml/Main.qml
        qml/DiscoverPage.qml
        qml/InstalledPage.qml
)

install(TARGETS ix1-software-center RUNTIME DESTINATION bin)
