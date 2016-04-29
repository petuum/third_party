THIRD_PARTY := $(shell readlink $(dir $(lastword $(MAKEFILE_LIST))) -f)
THIRD_PARTY_CENTRAL = $(THIRD_PARTY)/central
THIRD_PARTY_SRC = $(THIRD_PARTY)/src
THIRD_PARTY_INCLUDE = $(THIRD_PARTY)/include
THIRD_PARTY_LIB = $(THIRD_PARTY)/lib
THIRD_PARTY_BIN = $(THIRD_PARTY)/bin

BOOST_MINOR_VERSION = 58
BOOST_VERSION = 1_$(BOOST_MINOR_VERSION)_0
BOOST_PROJECT = boost_$(BOOST_VERSION)

PROJECTS_CORE = eigen \
	        gflags \
	        glog \
	        gperftools \
	        yaml-cpp \
	        sparsehash \
	        snappy \
	        libzmq

PROJECTS_ALL = $(PROJECTS_CORE) \
	       boost \
	       leveldb \
	       libcuckoo \
	       libconfig \
	       oprofile

CLEAN_TARGETS = $(PROJECTS_ALL:=.clean)
DISTCLEAN_TARGETS = $(PROJECTS_ALL:=.distclean)

all: third_party_all

third_party_core: path $(PROJECTS_CORE)


third_party_all: third_party_core \
	$(PROJECTS_ALL) \
	float_compressor

clean: $(CLEAN_TARGETS)
	rm -rf $(THIRD_PARTY_INCLUDE) $(THIRD_PARTY_LIB) $(THIRD_PARTY_BIN) \
	   $(THIRD_PARTY)/share
	@echo Done cleaning

distclean: $(DISTCLEAN_TARGETS)
	@echo Done cleaning

%.clean:
	$(MAKE) -C $(patsubst %.clean,$(THIRD_PARTY_SRC)/%,$@) clean || true

boost.distclean:
	rm -rf $(BOOST_SRC)

eigen.distclean:
	rm -rf $(EIGEN_SRC)

libconfig.distclean:
	rm -rf $(LIBCONFIG_SRC)


%.distclean:
	$(MAKE) -C $(patsubst %.distclean,$(THIRD_PARTY_SRC)/%,$@) distclean || true

.PHONY: third_party_core third_party_all clean distclean $(PROJECTS_ALL) path

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

BOOST_CENTRAL = $(THIRD_PARTY_CENTRAL)/boost_$(BOOST_VERSION).tar.bz2
BOOST_SRC = $(THIRD_PARTY_SRC)/boost
BOOST_INCLUDE = $(THIRD_PARTY_INCLUDE)/boost
BOOST_B2 = $(BOOST_SRC)/b2
BOOST_BOOTSTRAP = $(BOOST_SRC)/bootstrap.sh

BOOST_LIBRARIES = \
    python \

BOOST_FLAGS = $(BOOST_LIBRARIES:%=--with-% )

boost: path $(BOOST_INCLUDE)

$(BOOST_CENTRAL):
	wget http://downloads.sourceforge.net/project/boost/boost/1.$(BOOST_MINOR_VERSION).0/boost_1_$(BOOST_MINOR_VERSION)_0.tar.bz2 -O $(BOOST_CENTRAL)

$(BOOST_SRC): $(BOOST_BOOTSTRAP)

$(BOOST_BOOTSTRAP): $(BOOST_CENTRAL)
	if [ ! -d $(BOOST_SRC) ]; then \
	  tar jxf $< -C $(THIRD_PARTY_SRC) && \
	  mv $(THIRD_PARTY_SRC)/$(BOOST_PROJECT) $(BOOST_SRC) ; \
	fi
	touch $@

$(BOOST_B2): $(BOOST_BOOTSTRAP)
	cd $(BOOST_SRC) && \
	./bootstrap.sh --prefix=$(THIRD_PARTY)
	touch $@

$(BOOST_INCLUDE): $(BOOST_B2)
	cd $(BOOST_SRC) && \
	./b2 install -q $(BOOST_FLAGS)
	touch $@

# ===================== cuckoo =====================

CUCKOO_SRC = $(THIRD_PARTY_SRC)/libcuckoo
CUCKOO_INCLUDE = $(THIRD_PARTY_INCLUDE)/libcuckoo

$(CUCKOO_INCLUDE): $(CUCKOO_SRC)
	ln -s $(CUCKOO_SRC)/src $@

libcuckoo: path $(CUCKOO_INCLUDE)

# ==================== eigen ====================

EIGEN_CENTRAL = $(THIRD_PARTY_CENTRAL)/eigen-3.2.4.tar.bz2
EIGEN_SRC = $(THIRD_PARTY_SRC)/eigen
EIGEN_INCLUDE = $(THIRD_PARTY_INCLUDE)/Eigen

eigen: path $(EIGEN_INCLUDE)

$(EIGEN_CENTRAL):
	wget http://bitbucket.org/eigen/eigen/get/3.2.8.tar.bz2 -O $(EIGEN_CENTRAL)

$(EIGEN_SRC): $(EIGEN_CENTRAL)
	tar jxf $< -C $(THIRD_PARTY_SRC)
	mv $(THIRD_PARTY_SRC)/eigen* $(EIGEN_SRC)

$(EIGEN_INCLUDE): $(EIGEN_SRC)
	cp -r $(EIGEN_SRC)/Eigen \
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
LEVELDB_LIB = $(THIRD_PARTY_LIB)/libleveldb.a
LEVELDB_LIB_BUILD = $(LEVELDB_SRC)/libleveldb.a
LEVELDB_INCLUDE = $(THIRD_PARTY_INCLUDE)/leveldb

leveldb: path $(LEVELDB_LIB) $(LEVELDB_INCLUDE)

$(LEVELDB_LIB):
	LIBRARY_PATH=$(THIRD_PARTY_LIB):${LIBRARY_PATH} $(MAKE) -C $(LEVELDB_SRC)
	cp $(LEVELDB_SRC)/libleveldb.* $(THIRD_PARTY_LIB)

$(LEVELDB_INCLUDE):
	ln -s $(LEVELDB_SRC)/include $@

# ==================== libconfig ===================

LIBCONFIG_VERSION = 1.5
LIBCONFIG_TAR = $(THIRD_PARTY_CENTRAL)/libconfig-$(LIBCONFIG_VERSION).tar.gz
LIBCONFIG_SRC = $(THIRD_PARTY_SRC)/libconfig
LIBCONFIG_LIB = $(THIRD_PARTY_LIB)/libconfig++.so

libconfig: path $(LIBCONFIG_LIB)

$(LIBCONFIG_TAR):
	wget http://www.hyperrealm.com/libconfig/libconfig-$(LIBCONFIG_VERSION).tar.gz -O $@

$(LIBCONFIG_SRC): $(LIBCONFIG_TAR)
	tar xf $< -C $(THIRD_PARTY_SRC)
	mv $(LIBCONFIG_SRC)-$(LIBCONFIG_VERSION) $(LIBCONFIG_SRC)

$(LIBCONFIG_LIB): $(LIBCONFIG_SRC)
	cd $(LIBCONFIG_SRC) && \
	./configure --prefix=$(THIRD_PARTY) --enable-frame-pointers && \
	$(MAKE) install

# ==================== yaml-cpp ===================

YAMLCPP_SRC = $(THIRD_PARTY_SRC)/yaml-cpp
YAMLCPP_MK = $(THIRD_PARTY_SRC)/yaml-cpp.mk
YAMLCPP_LIB = $(THIRD_PARTY_LIB)/libyaml-cpp.a
YAMLCPP_INCLUDE = $(THIRD_PARTY_INCLUDE)/yaml-cpp

yaml-cpp: boost $(YAMLCPP_LIB) $(YAMLCPP_INCLUDE)

$(YAMLCPP_INCLUDE): $(YAMLCPP_LIB)
	cp -r $(YAMLCPP_SRC)/include/yaml-cpp $(YAMLCPP_INCLUDE)

$(YAMLCPP_LIB): $(YAMLCPP_SRC)
	cd $(YAMLCPP_SRC); \
	$(MAKE) -f $(YAMLCPP_MK) BOOST_PREFIX=$(THIRD_PARTY) TARGET=$@

# =================== oprofile ===================
# NOTE: need libpopt-dev binutils-dev

OPROFILE_SRC = $(THIRD_PARTY_SRC)/oprofile
OPROFILE_TARGET = $(OPROFILE_SRC)/pp/opreport

oprofile: path $(OPROFILE_TARGET)

$(OPROFILE_TARGET): $(OPROFILE_SRC)
	cd $(OPROFILE_SRC); \
	./autogen.sh && \
	./configure --prefix=$(THIRD_PARTY) && \
	$(MAKE) install

# ================== sparsehash ==================

SPARSEHASH_SRC = $(THIRD_PARTY_SRC)/sparsehash
SPARSEHASH_INCLUDE = $(THIRD_PARTY_INCLUDE)/sparsehash

sparsehash: path $(SPARSEHASH_INCLUDE)

$(SPARSEHASH_INCLUDE): $(SPARSEHASH_SRC)
	cd $(SPARSEHASH_SRC); \
	./configure --prefix=$(THIRD_PARTY) && \
	$(MAKE) install

# ==================== snappy ===================

SNAPPY_SRC = $(THIRD_PARTY_SRC)/snappy
SNAPPY_LIB = $(THIRD_PARTY_LIB)/libsnappy.so

snappy: path $(SNAPPY_LIB)

$(SNAPPY_LIB): $(SNAPPY_SRC)
	cd $(SNAPPY_SRC); \
	./autogen.sh && \
	./configure --prefix=$(THIRD_PARTY) && \
	$(MAKE) install

# ==================== libzmq ====================

ZMQ_SRC = $(THIRD_PARTY_SRC)/libzmq
ZMQ_HEADER_SRC = $(THIRD_PARTY_SRC)/zmq.hpp
ZMQ_LIB = $(THIRD_PARTY_LIB)/libzmq.so
ZMQ_CPP_HEADER = $(THIRD_PARTY_INCLUDE)/zmq.hpp

libzmq: path $(ZMQ_CPP_HEADER) $(ZMQ_LIB)

$(ZMQ_CPP_HEADER): $(ZMQ_HEADER_SRC)
	cp $< $@

$(ZMQ_LIB): $(ZMQ_SRC)
	cd $(ZMQ_SRC); \
	./autogen.sh && \
	./configure --prefix=$(THIRD_PARTY); \
	$(MAKE) install

