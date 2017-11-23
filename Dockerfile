FROM python:3.6.3-stretch

RUN echo "deb http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list \
 && echo "deb http://ftp.uk.debian.org/debian experimental main" >> /etc/apt/sources.list \
 && curl https://storage.googleapis.com/bazel-apt/doc/apt-key.pub.gpg | apt-key add - \
 && apt-get -y update \
 && apt-get -y install autoconf-archive automake g++ libtool pkg-config unzip build-essential cmake \
    libatlas-base-dev gfortran libgtk2.0-dev libavcodec-dev libavformat-dev libswscale-dev libjpeg-dev libpng-dev \
    libtiff-dev libv4l-dev libleptonica-dev openjdk-8-jdk openjdk-8-jre-headless ca-certificates-java \
    clang-format-3.8 libcurl4-openssl-dev libtool python-dev python-setuptools python-virtualenv \
    python3-dev python3-setuptools zlib1g-dev bazel\
 && pip install numpy==1.13.3 wheel \
 && update-ca-certificates -f

# install tensorflow from sources
RUN curl -sSL https://github.com/tensorflow/tensorflow/archive/r1.4.zip -o tensorflow.zip \
 && unzip -q tensorflow.zip && mv /tensorflow-r1.4 /tensorflow && rm tensorflow.zip \
 && cd tensorflow \
 && tensorflow/tools/ci_build/builds/configured CPU \
 && touch WORKSPACE \
 && echo "startup --batch\nbuild --spawn_strategy=standalone --genrule_strategy=standalone" >>/etc/bazel.bazelrc \
 && bazel build -c opt --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-mfpmath=both --copt=-msse4.2 \
    --output_filter='^//tensorflow'  //tensorflow/tools/pip_package:build_pip_package \
 && bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg \
 && pip install --upgrade /tmp/tensorflow_pkg/tensorflow-*.whl \
 && cd / && rm -rf /root/.cache /tmp/tensorflow_pkg tensorflow

# install opencv3.3.0
RUN curl -sSL https://github.com/Itseez/opencv/archive/3.3.0.zip -o opencv3.zip \
 && unzip -q opencv3.zip && mv /opencv-3.3.0 /opencv && rm opencv3.zip \
 && curl -sSL https://github.com/Itseez/opencv_contrib/archive/3.3.0.zip -o opencv_contrib3.zip \
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
 && rm -rf /opencv /opencv_contrib

# install tesseract4
RUN cd / \
 && apt-get install -y -t experimental libtesseract-dev \
 && curl -sSL https://github.com/tesseract-ocr/tesseract/archive/ebbfc3ae8df85c351002000a76900e3086375e7b.zip -o tesseract-ocr.zip \
 && unzip tesseract-ocr.zip && rm tesseract-ocr.zip \
 && cd tesseract-*/ \
 && . ./autogen.sh \
 && ./configure \
 && make \
 && make install \
 && ldconfig \
 && cd .. \
 && rm -rf tesseract-*/ \
 && curl -sSL 'https://github.com/tesseract-ocr/tessdata/blob/master/eng.traineddata?raw=true' \
    -o /usr/local/share/eng.traineddata \
 && CPPFLAGS=-DUSE_STD_NAMESPACE pip install tesserocr==2.2.2

# clean up
RUN apt-get -y remove --purge autoconf-archive automake g++ libtool unzip build-essential cmake pkg-config  \
    libatlas-base-dev gfortran libgtk2.0-dev libavcodec-dev libavformat-dev libswscale-dev \
    libjpeg-dev libpng-dev libtiff-dev libv4l-dev libcurl4-openssl-dev libtool zlib1g-dev\
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
