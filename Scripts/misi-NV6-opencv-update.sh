#!/bin/bash
#OpenCV 3.2.0 On NV6 N-series Azure
clear


misi_log()
{
	echo ""
	NOW=$(date)
	MISI_SEP="+----------------------------------------------------------------------"
	echo $MISI_SEP
	echo " | Misi:				$NOW"
	echo $MISI_SEP
	echo " | "$1
	echo $MISI_SEP
	echo ""
}

misi_intro()
{
	misi_log "Hey :)"
	misi_log "Installing OpenCV"
}

misi_update_os()
{
	misi_log "Updating OS (Linux)..."
	apt-get -qq update 
	apt-get -qq -y upgrade
	misi_log "Uninstall the current version running..."
	apt-get autoremove libopencv-dev python-opencv
	misi_log "OS updated & Old OpenCV version uninstalled:)"
}

misi_update_cuda_profiles()
{
	if grep -r "MISI :]" "~/.bashrc";
	then 
		misi_log "Profile file already updated"
	else
		echo "# MISI :]" >> ~/.bashrc
		echo "CUDA_HOME=/usr/local/cuda-8.0" >> ~/.bashrc
		echo "LD_LIBRARY_PATH=${CUDA_HOME}/lib64" >> ~/.bashrc
		echo "PATH=/usr/local/cuda-8.0/bin${PATH:+:${PATH}}" >> ~/.bashrc
		echo "PATH=${CUDA_HOME}/bin:${PATH}" >> ~/.bashrc
		source ~/.bashrc
		misi_log "Profile file updated"
	fi
}

misi_opencv_setup()
{
	MISI_OPENCV_REQUIERED_INSTALLATION="build-essential cmake checkinstall pkg-config"
	apt-get -qq install $MISI_OPENCV_REQUIERED_INSTALLATION
	misi_log "Compiling and installing OpenCV"
	  typeset src_dir=/var/opencv
	  typeset opencv_ver="3.2.0"
	  typeset opencv_link="https://github.com/opencv/opencv/archive/${opencv_ver}.tar.gz"
	  	mkdir -p ${src_dir}
	    cd ${src_dir}
	    wget ${opencv_link}
	    cd opencv-${opencv_ver}
	    cd /usr/include/linux
	    sudo ln -s ../libv4l1-videodev.h videodev.h
	    cd -
	    sudo mkdir build
	    cd build
	    cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local \
	          -D BUILD_NEW_PYTHON_SUPPORT=ON -D WITH_QT=ON -D WITH_OPENGL=ON \
	          -D WITH_1394=OFF -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-8.0 \
	          -DCUDA_ARCH_BIN='3.0 3.5 5.0 6.0 6.2' -DCUDA_ARCH_PTX="" \
	          -DOPENCV_TEST_DATA_PATH=../opencv_extra/testdata .. 
	    make -j6
	    checkinstall
	    /bin/bash -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf'
	    ldconfig
	    make install
	  misi_log "Creating link to libippicv.a"
	  	sudo cp /var/opencv/opencv-3.2.0/build/3rdparty/ippicv/ippicv_lnx/lib/intel64/libippicv.a /usr/local/lib/
	  misi_log "Updating ld libs"
	  	sh -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf'
	  ldconfig
	  misi_log "Creating link from /dev/null to /dev/raw1394"
	  	ln /dev/null /dev/raw1394
	  	ldconfig -v
	    updatedb && locate libopencv_core.so.${opencv_ver}
	  misi_log "Testing the OpenCV installation"
	    pkg-config --modversion opencv - Checks version
	  misi_log "OpenCV setup updated :)"
}

# MISI MAIN FLOW

misi_intro
misi_update_os
misi_update_cuda_profiles
misi_opencv_setup