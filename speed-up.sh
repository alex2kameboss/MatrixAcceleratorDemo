# 4 lanes
make ma_test_build GCC_ARGS="-DN_LANES=4 -DTEST_16 -DTEST_32 -DTEST_64 -DTEST_128"
make sim DEFINES="-D PRF_LOG_P=1 -D PRF_LOG_Q=1" LOG_FILE=sim_4_lanes.log

# 8 lanes
make ma_test_build GCC_ARGS="-DN_LANES=8 -DTEST_32 -DTEST_64 -DTEST_128"
make sim DEFINES="-D PRF_LOG_P=1 -D PRF_LOG_Q=2" LOG_FILE=sim_8_lanes.log

# 16 lanes
make ma_test_build GCC_ARGS="-DN_LANES=16 -DTEST_64 -DTEST_128"
make sim DEFINES="-D PRF_LOG_P=2 -D PRF_LOG_Q=2" LOG_FILE=sim_16_lanes.log

# 32 lanes
make ma_test_build GCC_ARGS="-DN_LANES=32 -DTEST_128"
make sim DEFINES="-D PRF_LOG_P=2 -D PRF_LOG_Q=3" LOG_FILE=sim_32_lanes.log
