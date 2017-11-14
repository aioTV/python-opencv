FROM python:3.6.3-stretch

RUN apt-get -y update \
  && apt-get -y install autoconf-archive automake g++ libtool pkg-config wget unzip build-essential cmake \
     libatlas-base-dev gfortran libgtk2.0-dev libavcodec-dev libavformat-dev libswscale-dev libjpeg-dev libpng-dev \
     libtiff-dev libv4l-dev libleptonica-dev \
  && curl -sSL https://github.com/tesseract-ocr/tesseract/archive/ebbfc3ae8df85c351002000a76900e3086375e7b.zip -o tesseract-ocr.zip \
  && unzip tesseract-ocr.zip \
  && cd tesseract-ebbfc3ae8df85c351002000a76900e3086375e7b \
  && . ./autogen.sh \
  && ./configure \
  && make \
  && make install \
  && ldconfig \
  && cd .. \
  && wget https://github.com/tesseract-ocr/tessdata/blob/master/eng.traineddata?raw=true \
      -O /usr/local/share/eng.traineddata \
 && pip install numpy==1.13.3 \
 && wget https://github.com/Itseez/opencv/archive/3.3.0.zip -O opencv3.zip \
 && unzip -q opencv3.zip && mv /opencv-3.3.0 /opencv && rm opencv3.zip \
 && wget https://github.com/Itseez/opencv_contrib/archive/3.3.0.zip -O opencv_contrib3.zip \
 && unzip -q opencv_contrib3.zip && mv /opencv_contrib-3.3.0 /opencv_contrib && rm opencv_contrib3.zip \
 && mkdir /opencv/build && cd /opencv/build \
 && cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D BUILD_PYTHON_SUPPORT=ON \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D OPENCV_EXTRA_MODULES_PATH=/opencv_contrib/modules \
          -D BUILD_EXAMPLES=OFF \
          -D PYTHON_DEFAULT_EXECUTABLE=/usr/bin/python \
          -D BUILD_opencv_python3=ON \
          -D BUILD_opencv_python2=OFF \
          -D WITH_IPP=OFF \
          -D WITH_FFMPEG=ON \
          -D WITH_V4L=ON .. \
 && cd /opencv/build && make -j$(nproc) && make install && ldconfig \
 && apt-get -y remove --purge wget unzip build-essential cmake pkg-config libatlas-base-dev gfortran \
                              libgtk2.0-dev libavcodec-dev libavformat-dev libswscale-dev libjpeg-dev libpng-dev \
                              libtiff-dev libv4l-dev \
 && apt-get clean \
 && rm -rf /opencv /opencv_contrib /var/lib/apt/lists/*
