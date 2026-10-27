#include <cstdio>

namespace {

struct A {
    virtual ~A() {}
    int a = 1;
};

struct B : A {
    int b = 2;
};

struct C : A {
    int c = 3;
};

struct D : B, C {
    int d = 4;
};

}  // namespace

// Down, cross and whole-object casts from each of the two A subobjects of D : B, C.
extern "C" void ipahle_run_cpp_casts(void) {
    D whole;
    A *fromB = static_cast<B *>(&whole);
    A *fromC = static_cast<C *>(&whole);
    std::printf("CAST_CPP fromB down_B=%d down_D=%d cross_C=%d\n",
                dynamic_cast<B *>(fromB) != nullptr,
                dynamic_cast<D *>(fromB) != nullptr,
                dynamic_cast<C *>(fromB) != nullptr);
    std::printf("CAST_CPP fromC down_C=%d down_D=%d cross_B=%d\n",
                dynamic_cast<C *>(fromC) != nullptr,
                dynamic_cast<D *>(fromC) != nullptr,
                dynamic_cast<B *>(fromC) != nullptr);
    std::printf("CAST_CPP distinct=%d\n", fromB != fromC);
}
