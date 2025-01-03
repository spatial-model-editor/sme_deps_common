# cmake file for https://www.qcustomplot.com/

cmake_minimum_required(VERSION 3.16...3.31)

project(
  QCustomPlot
  VERSION 2.1.1
  DESCRIPTION "QCustomPlot"
  LANGUAGES CXX)

# workaround for https://gitlab.kitware.com/cmake/cmake/-/issues/25974
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

add_library(qcustomplot STATIC qcustomplot.cpp)
add_library(qcustomplot::qcustomplot ALIAS qcustomplot)

set_target_properties(qcustomplot PROPERTIES CXX_STANDARD 20)
set_target_properties(qcustomplot PROPERTIES POSITION_INDEPENDENT_CODE ON)

set(WITH_QT6
    on
    CACHE BOOL "Use Qt6")
if(WITH_QT6)
  find_package(
    Qt6
    COMPONENTS Widgets PrintSupport
    REQUIRED)
else()
  find_package(
    Qt5
    COMPONENTS Widgets PrintSupport
    REQUIRED)
endif()
target_link_libraries(qcustomplot PRIVATE Qt::Widgets Qt::PrintSupport)

include(GNUInstallDirs)
set(INSTALL_CONFIGDIR ${CMAKE_INSTALL_LIBDIR}/cmake/qcustomplot)
install(
  TARGETS qcustomplot
  EXPORT qcustomplot-targets
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES qcustomplot.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
target_include_directories(
  qcustomplot PUBLIC $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
                     $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}>)
set_target_properties(qcustomplot PROPERTIES EXPORT_NAME qcustomplot)
install(
  EXPORT qcustomplot-targets
  FILE qcustomplotTargets.cmake
  NAMESPACE qcustomplot::
  DESTINATION ${INSTALL_CONFIGDIR})
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/qcustomplotConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY AnyNewerVersion)
configure_package_config_file(
  ${CMAKE_CURRENT_LIST_DIR}/cmake/qcustomplotConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/qcustomplotConfig.cmake
  INSTALL_DESTINATION ${INSTALL_CONFIGDIR})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/qcustomplotConfig.cmake
              ${CMAKE_CURRENT_BINARY_DIR}/qcustomplotConfigVersion.cmake
        DESTINATION ${INSTALL_CONFIGDIR})
export(
  EXPORT qcustomplot-targets
  FILE ${CMAKE_CURRENT_BINARY_DIR}/qcustomplotTargets.cmake
  NAMESPACE qcustomplot::)
export(PACKAGE qcustomplot)
