
# typing.py - Dummy typing module for MicroPython type hint compatibility

class GenericMeta:
    def __getitem__(self, params):
        return Any

class AnyType(GenericMeta):
    pass

Any = AnyType()
Callable = GenericMeta()
Optional = GenericMeta()
List = GenericMeta()
Dict = GenericMeta()
Tuple = GenericMeta()
Union = GenericMeta()
Type = GenericMeta()
BinaryIO = GenericMeta()
IO = GenericMeta()
TextIO = GenericMeta()
Tuple = GenericMeta()
List = GenericMeta()
Dict = GenericMeta()
Set = GenericMeta()
FrozenSet = GenericMeta()
Sequence = GenericMeta()
Iterable = GenericMeta()
Iterator = GenericMeta()
Generator = GenericMeta()
Hashable = GenericMeta()
Sized = GenericMeta()
Container = GenericMeta()
Mapping = GenericMeta()
MutableMapping = GenericMeta()
Sequence = GenericMeta()
MutableSequence = GenericMeta()
Set = GenericMeta()
MutableSet = GenericMeta()
