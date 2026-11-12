class Base:
    def who(self):
        return "Base"

class A(Base):
    def who(self):
        return "A " + super().who()

class B(Base):
    def who(self):
        return "B " + super().who()

class C(A, B):
    def who(self):
        return "C " + super().who()

print(C().who())
