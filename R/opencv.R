#' @title Check OpenCV Installation
#'
#' @description This functions checks that OpenCV is installed within the R
#'  library.
#'
#' @return A boolean indicating whether OpenCV was or not installed on the system.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
isOpenCVInstalled <- function() {
  pkgPath <- find.package("ROpenCVLite")
  dir.exists(paste0(pkgPath, "/opencv/include/"))
}


#' @title Install OpenCV
#'
#' @description This function will attempt to download, compile and install
#'  OpenCV on the system. This process will take several minutes.
#'
#' @param force A logical indicating whether the interactive dialogs preceding
#'  the installation should be skipped or not. If `TRUE` then the installation
#'  will begin immediately. If `FALSE` (the default), then a confirmation dialog
#'  will be displayed before the installation starts.
#'
#' @return A boolean indicating whether OpenCV was or not installed on the system.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
installOpenCV <- function(force = FALSE) {
  pkgPath <- find.package("ROpenCVLite")
  openCVPath <- paste0(pkgPath, "/opencv")

  install <- 0

  if (force) {
    install <- 1
  } else if (isOpenCVInstalled()) {
    if (interactive()) {
      install <- utils::menu(c("yes", "no"), title = "Do you want to reinstall OpenCV on this system? This will take several minutes.")
    }
  } else {
    if (interactive()) {
      install <- utils::menu(c("yes", "no"), title = "OpenCV is not installed on this system. Would you like to install it now? This will take several minutes.")
    }
  }

  if (install == 1) {
    Sys.setenv(CXX_STD = "CXX11")

    if (.Platform$OS.type == "windows") {
      origDir <- getwd()
      setwd(pkgPath)
      dir.create("opencv")
      dir.create("tmp")
      setwd("tmp")
      utils::download.file("https://github.com/opencv/opencv/archive/4.1.0.tar.gz",
                    "opencv-4.1.0.tar.gz")
      utils::untar("opencv-4.1.0.tar.gz")

      file.copy("../OpenCVDetectDirectX.4.1.0.cmake", "opencv-4.1.0/cmake/OpenCVDetectDirectX.cmake",
                overwrite = TRUE)
      file.copy("../OpenCVDetectOpenCL.4.1.0.cmake", "opencv-4.1.0/cmake/OpenCVDetectOpenCL.cmake",
                overwrite = TRUE)

      setwd("opencv-4.1.0")

      arch <- c("64", "32")
      archAvail <- c(dir.exists(paste0(R.home(), "/bin/x64")),
                       dir.exists(paste0(R.home(), "/bin/i386")))

      if (any(archAvail)) {
        pkgbuild::check_rtools()
        rtoolsPath <- gsub("/bin", "", pkgbuild::rtools_path())

        for (i in 1:2) {
          if (archAvail[i]) {
            dir.create(paste0("build", arch[i]))
            setwd(paste0("build", arch[i]))
            system(paste0('cmake -G "Unix Makefiles" -DCMAKE_C_COMPILER=', rtoolsPath, '/mingw_', arch[i], '/bin/gcc.exe -DCMAKE_CXX_COMPILER=', rtoolsPath, '/mingw_', arch[i], '/bin/g++.exe -DCMAKE_RC_COMPILER=', rtoolsPath, '/mingw_', arch[i], '/bin/windres.exe -DCMAKE_MAKE_PROGRAM=', rtoolsPath, '/mingw_', arch[i], '/bin/mingw32-make.exe -DENABLE_PRECOMPILED_HEADERS=OFF -DENABLE_CXX11=ON -DBUILD_ZLIB=ON -DBUILD_opencv_world=OFF -DBUILD_opencv_contrib_world=OFF -DBUILD_matlab=OFF -DBUILD_opencv_java=OFF -DBUILD_opencv_python2=OFF -DBUILD_opencv_python3=OFF -DBUILD_PERF_TESTS=OFF -DBUILD_TESTS=OFF -DWITH_MSMF=OFF -DBUILD_PROTOBUF=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=', openCVPath, ' ../'))
            system(paste0(rtoolsPath, "/mingw_", arch[i], "/bin/mingw32-make.exe -j4"))
            system(paste0(rtoolsPath, "/mingw_", arch[i], "/bin/mingw32-make.exe install"))
            setwd("../")
          }
        }
      }
      setwd(pkgPath)
      unlink("tmp", recursive = TRUE)
      setwd(origDir)
    } else {
      origDir <- getwd()
      setwd(pkgPath)
      dir.create("opencv")
      dir.create("tmp")
      setwd("tmp")
      utils::download.file("https://github.com/opencv/opencv/archive/4.1.0.zip",
                    "opencv-4.1.0.zip")
      utils::unzip("opencv-4.1.0.zip")

      file.copy("../OpenCVModule.4.1.0.cmake", "opencv-4.1.0/cmake/OpenCVModule.cmake",
                overwrite = TRUE)

      setwd("opencv-4.1.0")
      dir.create("build")
      setwd("build")
      system(paste0("cmake -DWITH_IPP=ON -DBUILD_opencv_world=OFF -DBUILD_opencv_contrib_world=OFF -DBUILD_opencv_matlab=OFF -DBUILD_opencv_java=OFF -DBUILD_opencv_python2=OFF -DBUILD_opencv_python3=OFF -DBUILD_PERF_TESTS=OFF -DBUILD_TESTS=OFF -DINSTALL_CREATE_DISTRIB=ON -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=", openCVPath, " ../"))
      system("make -j4; make all install")
      setwd(pkgPath)
      unlink("tmp", recursive = TRUE)
      setwd(origDir)
    }
  } else {
    message("OpenCV was not installed at this time. You can install it at any time by using the installOpenCV() function.")
  }

  isOpenCVInstalled()
}


#' @title OpenCV version
#'
#' @description Determines the version of OpenCV installed within R.
#'
#' @return A character string with the version of OpenCV installed by
#'  \code{\link{ROpenCVLite}}.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
opencvVersion <- function() {
  if (isOpenCVInstalled()) {
    pkgPath <- find.package("ROpenCVLite")

    if (.Platform$OS.type == "windows") {
      pcPath <- "/opencv/OpenCVConfig-version.cmake"
      pc <- utils::read.table(paste0(pkgPath, pcPath), sep = "\t")[1, 1]
      paste0("Version ", gsub(")", "", gsub(".*VERSION ", "", pc)))
    } else {
      pcPath <- "/opencv/lib/cmake/opencv4/OpenCVConfig-version.cmake"
      pc <- utils::read.table(paste0(pkgPath, pcPath), sep = "\t")[1, 1]
      paste0("Version ", gsub(")", "", gsub(".*VERSION ", "", pc)))
    }
  } else {
    stop("OpenCV is not installed on this system. Please use installOpenCV() to install it.")
  }
}


#' @title C/C++ configuration options
#'
#' @description Determines the configuration options for compiling C/C++-based
#'  packages against OpenCV installed by \code{\link{ROpenCVLite}}.
#'
#' @param output Either 'libs' for library configuration options or 'cflags' for
#'  C/C++ configuration flags.
#'
#' @param arch architecture relevant for Windows.  If \code{NULL},
#' then \code{R.version$arch} will be used.
#'
#' @return A concatenated character string (with \code{\link{cat}}) of the
#'  configuration options.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
opencvConfig <- function(output = "libs", arch = NULL) {
  if (!isOpenCVInstalled())
    stop("OpenCV is not installed on this system. Please use installOpenCV() to install it.")

  pkgPath <- find.package("ROpenCVLite")
  prefix <- paste0(pkgPath, "/opencv")

  if (output == "libs") {
    if (.Platform$OS.type == "windows") {
      if (is.null(arch)) {
        arch = R.version$arch
      }
      if (grepl("i386", arch)) {
        execPrefix <- paste0(prefix, "/x86/mingw")
      } else {
        execPrefix <- paste0(prefix, "/x64/mingw")
      }
      libDir <- paste0(execPrefix, "/lib")
      libs <- gsub("libopencv", "opencv", list.files(libDir, "lib*"))
      libs <- gsub("\\.a", "", libs)
      libs <- gsub("\\.dll", "", libs)
      libs <- ifelse(substring(libs, 1, 3) == "lib", substring(libs, 4), libs)
      libs <- paste0("-l", libs)
      cat(paste0('-L"', utils::shortPathName(libDir), '"'), libs)
    } else {
      execPrefix <- prefix
      libDir <- paste0(execPrefix, "/lib")
      libs <- gsub("libopencv", "opencv", list.files(libDir, "lib*"))
      libs <- gsub("\\.so", "", libs)
      libs <- gsub("\\.dylib", "", libs)
      libs <- libs[!grepl("\\.", libs)]
      libs <- paste0("-l", libs)
      if (Sys.info()[1] == "Darwin") {
        cat(paste0("-L", libDir, " ", paste0(libs, collapse = " ")))
      } else {
        cat(paste0("-Wl,-rpath=", libDir, " ", "-L", libDir, " ", paste0(libs, collapse = " ")))
      }
    }
  } else if (output == "cflags") {
    if (.Platform$OS.type == "windows") {
      includedirOld <- paste0(prefix, "/include/opencv2")
      includedirNew <- paste0(prefix, "/include")

      if (is.null(arch)) {
        arch = R.version$arch
      }
      if (grepl("i386", arch)) {
        execdir <- paste0(prefix, "/x86/mingw/bin")
      } else {
        execdir <- paste0(prefix, "/x64/mingw/bin")
      }

      cat(paste0('-I"', utils::shortPathName(includedirOld), '" -I"',
                 utils::shortPathName(includedirNew), '" -I"',
                 utils::shortPathName(execdir), '"'))
    } else {
      includedirOld <- paste0(prefix, "/include/opencv4")
      includedirNew <- paste0(prefix, "/include")

      cat(paste0("-I", includedirOld, " -I", includedirNew))
    }
  } else {
    stop("output should be either 'libs' or 'cflags'")
  }
}
