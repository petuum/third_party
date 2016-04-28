THIRD_PARTY := $(shell readlink $(dir $(lastword $(MAKEFILE_LIST))) -f)
THIRD_PARTY_CENTRAL = $(THIRD_PARTY)/central
THIRD_PARTY_SRC = $(THIRD_PARTY)/src
THIRD_PARTY_INCLUDE = $(THIRD_PARTY)/include
THIRD_PARTY_LIB = $(THIRD_PARTY)/lib
THIRD_PARTY_BIN = $(THIRD_PARTY)/bin

all: third_party_all

third_party_core: path \
	gflags \
	glog \
	gperftools \
	snappy \
	sparsehash \
	fastapprox \
	yaml-cpp \
	eigen \
	zeromq


third_party_all: third_party_core \
	oprofile \
	boost \
	libconfig \
	cuckoo \
	leveldb \
	float_compressor

distclean:
	rm -rf $(THIRD_PARTY_INCLUDE) $(THIRD_PARTY_LIB) $(THIRD_PARTY_BIN) \
	$(THIRD_PARTY_SRC) $(THIRD_PARTY)/share

.PHONY: third_party_core third_party_all distclean

$(THIRD_PARTY_LIB):
	mkdir -p $@

$(THIRD_PARTY_INCLUDE):
	mkdir -p $@

$(THIRD_PARTY_BIN):
	mkdir -p $@

$(THIRD_PARTY_SRC):
	mkdir -p $@

path: $(THIRD_PARTY_LIB) \
      $(THIRD_PARTY_INCLUDE) \
      $(THIRD_PARTY_BIN) \
      $(THIRD_PARTY_SRC)

# ==================== boost ====================

BOOST_MINOR_VERSION = 58
BOOST_VERSION = 1_$(BOOST_MINOR_VERSION)_0
BOOST_CENTRAL = $(THIRD_PARTY_CENTRAL)/boost_$(BOOST_VERSION).tar.bz2
BOOST_SRC = $(basename $(basename $(THIRD_PARTY_SRC)/$(notdir $(BOOST_CENTRAL))))
BOOST_INCLUDE = $(THIRD_PARTY_INCLUDE)/boost
BOOST_B2 = $(BOOST_SRC)/b2

BOOST_LIBRARIES = \
    python \

BOOST_FLAGS = $(BOOST_LIBRARIES:%=--with-% )

boost: path $(BOOST_INCLUDE)

$(BOOST_CENTRAL):
	wget http://downloads.sourceforge.net/project/boost/boost/1.$(BOOST_MINOR_VERSION).0/boost_1_$(BOOST_MINOR_VERSION)_0.tar.bz2 -O $(BOOST_CENTRAL)

$(BOOST_SRC): $(BOOST_CENTRAL)
	tar jxf $< -C $(THIRD_PARTY_SRC)

$(BOOST_B2): $(BOOST_SRC)
	cd $(BOOST_SRC) && \
	./bootstrap.sh --prefix=$(THIRD_PARTY)

$(BOOST_INCLUDE): $(BOOST_B2)
	cd $(BOOST_SRC) && \
	./b2 install -q $(BOOST_FLAGS)

# ===================== cuckoo =====================

CUCKOO_SRC = $(THIRD_PARTY_SRC)/libcuckoo
CUCKOO_INCLUDE = $(THIRD_PARTY_INCLUDE)/libcuckoo

$(CUCKOO_INCLUDE): $(CUCKOO_SRC)
	ln -s $(CUCKOO_SRC)/src $@

cuckoo: path $(CUCKOO_INCLUDE)

# ==================== eigen ====================

EIGEN_SRC = $(THIRD_PARTY_CENTRAL)/eigen-3.2.4.tar.bz2
EIGEN_INCLUDE = $(THIRD_PARTY_INCLUDE)/Eigen

eigen: path $(EIGEN_INCLUDE)

$(EIGEN_SRC):
	wget http://bitbucket.org/eigen/eigen/get/3.2.8.tar.bz2 -O $(EIGEN_SRC)

$(EIGEN_INCLUDE): $(EIGEN_SRC)
	tar jxf $< -C $(THIRD_PARTY_SRC)
	cp -r $(THIRD_PARTY_SRC)/eigen-eigen-10219c95fe65/Eigen \
		$(THIRD_PARTY_INCLUDE)/

# ==================== fastapprox ===================

FASTAPPROX_SRC = $(THIRD_PARTY_SRC)/fastapprox
FASTAPPROX_INCLUDE = $(THIRD_PARTY_INCLUDE)/fastapprox

fastapprox: path $(FASTAPPROX_INCLUDE)

$(FASTAPPROX_INCLUDE): $(FASTAPPROX_SRC)
	ln -s $(FASTAPPROX_SRC)/fastapprox/src/ $@

# ==================== float_compressor ====================

FC_INCLUDE = $(THIRD_PARTY_INCLUDE)/float16_compressor.hpp

$(FC_INCLUDE):
	wget http://www.cs.cmu.edu/~jinlianw/third_party/float16_compressor.hpp -O $@

float_compressor: path $(FC_INCLUDE)

# ===================== gflags ===================

GFLAGS_SRC = $(THIRD_PARTY_SRC)/gflags
GFLAGS_LIB = $(THIRD_PARTY_LIB)/libgflags.so

gflags: path $(GFLAGS_LIB)

$(GFLAGS_LIB): $(GFLAGS_SRC)
	cd $(GFLAGS_SRC); \
	./configure --prefix=$(THIRD_PARTY) && \
	$(MAKE) install

# ===================== glog =====================

GLOG_SRC = $(THIRD_PARTY_SRC)/glog
GLOG_LIB = $(THIRD_PARTY_LIB)/libglog.so

glog: $(GLOG_LIB)

$(GLOG_LIB): $(GLOG_SRC)
	cd $(GLOG_SRC); \
	./configure --prefix=$(THIRD_PARTY) && \
	$(MAKE) install

# ================== gperftools =================

GPERFTOOLS_SRC = $(THIRD_PARTY_SRC)/gperftools
GPERFTOOLS_LIB = $(THIRD_PARTY_LIB)/libtcmalloc.so

gperftools: path $(GPERFTOOLS_LIB)

$(GPERFTOOLS_LIB): $(GPERFTOOLS_SRC)
	cd $(GPERFTOOLS_SRC); \
	./autogen.sh && \
	./configure --prefix=$(THIRD_PARTY) --enable-frame-pointers && \
	$(MAKE) install

# ==================== leveldb ===================

LEVELDB_SRC = $(THIRD_PARTY_SRC)/leveldb
LEVELDB_LIB = $(THIRD_PARTY_LIB)/libleveldb.so
LEVELDB_LIB_BUILD = $(LEVELDB_SRC)/libleveldb.so
LEVELDB_INCLUDE = $(THIRD_PARTY_INCLUDE)/leveldb

leveldb: path $(LEVELDB_LIB) $(LEVELDB_INCLUDE)

leveldb_build: LIBRARY_PATH=$(THIRD_PARTY_LIB):${LIBRARY_PATH}
$(LEVELDB_INCLUDE_BUILD): $(LEVELDB_SRC) $(SNAPPY_LIB)
	$(MAKE) -C $(LEVELDB_SRC)

$(LEVELDB_LIB): $(LEVELDB_LIB_BUILD)
	cp $(LEVELDB_SRC)/libleveldb.* $(THIRD_PARTY_LIB)

$(LEVELDB_INCLUDE):
	ln -s $(LEVELDB_SRC)/include $@

# ==================== libconfig ===================

LIBCONFIG_TAR = $(THIRD_PARTY_CENTRAL)/libconfig-1.5.tar.gz
LIBCONFIG_SRC = $(THIRD_PARTY_SRC)/libconfig-1.5
LIBCONFIG_LIB = $(THIRD_PARTY_LIB)/libconfig++.so

libconfig: path $(LIBCONFIG_LIB)

$(LIBCONFIG_TAR):
	wget http://www.hyperrealm.com/libconfig/libconfig-1.5.tar.gz -O $@

$(LIBCONFIG_SRC): $(LIBCONFIG_TAR)
	tar xf $< -C $(THIRD_PARTY_SRC)

$(LIBCONFIG_LIB): $(LIBCONFIG_SRC)
	cd $(LIBCONFIG_SRC) && \
	./configure --prefix=$(THIRD_PARTY) --enable-frame-pointers && \
	$(MAKE) install

# ==================== yaml-cpp ===================

YAMLCPP_SRC = $(THIRD_PARTY_SRC)/yaml-cpp
YAMLCPP_MK = $(THIRD_PARTY_SRC)/yaml-cpp.mk
YAMLCPP_LIB = $(THIRD_PARTY_LIB)/libyaml-cpp.a
YAMLCPP_INCLUDE = $(THIRD_PARTY_INCLUDE)/yaml-cpp

yaml-cpp: boost $(YAMLCPP_LIB)

$(YAMLCPP_INCLUDE): $(YAMLCPP_LIB)
	ln -s $(YAMLCPP_SRC)/include $(YAMLCPP_INCLUDE)

$(YAMLCPP_LIB): $(YAMLCPP_SRC)
	cd $(YAMLCPP_SRC); \
	$(MAKE) -f $(YAMLCPP_MK) BOOST_PREFIX=$(THIRD_PARTY) TARGET=$@

# =================== oprofile ===================
# NOTE: need libpopt-dev binutils-dev

OPROFILE_SRC = $(THIRD_PARTY_CENTRAL)/oprofile-1.0.0.tar.gz
OPROFILE_LIB = $(THIRD_PARTY_LIB)/libprofiler.so

oprofile: path $(OPROFILE_LIB)

$(OPROFILE_LIB): $(OPROFILE_SRC)
	tar zxf $< -C $(THIRD_PARTY_SRC)
	cd $(basename $(basename $(THIRD_PARTY_SRC)/$(notdir $<))); \
	./configure --prefix=$(THIRD_PARTY); \
	make install

# ================== sparsehash ==================

SPARSEHASH_SRC = $(THIRD_PARTY_CENTRAL)/sparsehash-2.0.2.tar.gz
SPARSEHASH_INCLUDE = $(THIRD_PARTY_INCLUDE)/sparsehash

sparsehash: path $(SPARSEHASH_INCLUDE)

$(SPARSEHASH_INCLUDE): $(SPARSEHASH_SRC)
	tar zxf $< -C $(THIRD_PARTY_SRC)
	cd $(basename $(basename $(THIRD_PARTY_SRC)/$(notdir $<))); \
	./configure --prefix=$(THIRD_PARTY); \
	make install

# ==================== snappy ===================

SNAPPY_SRC = $(THIRD_PARTY_CENTRAL)/snappy-1.1.2.tar.gz
SNAPPY_LIB = $(THIRD_PARTY_LIB)/libsnappy.so

snappy: path $(SNAPPY_LIB)

$(SNAPPY_LIB): $(SNAPPY_SRC)
	tar zxf $< -C $(THIRD_PARTY_SRC)
	cd $(basename $(basename $(THIRD_PARTY_SRC)/$(notdir $<))); \
	./configure --prefix=$(THIRD_PARTY); \
	make install

# ==================== zeromq ====================

ZMQ_SRC = $(THIRD_PARTY_CENTRAL)/zeromq-3.2.5.tar.gz
ZMQ_LIB = $(THIRD_PARTY_LIB)/libzmq.so

zeromq: path $(ZMQ_LIB)

$(ZMQ_LIB): $(ZMQ_SRC)
	tar zxf $< -C $(THIRD_PARTY_SRC)
	cd $(basename $(basename $(THIRD_PARTY_SRC)/$(notdir $<))); \
	./configure --prefix=$(THIRD_PARTY); \
	make install
	cp $(THIRD_PARTY_CENTRAL)/zmq.hpp $(THIRD_PARTY_INCLUDE)

