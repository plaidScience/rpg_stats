class Stat {
  var _name;
  get name => _name;
  set name (var potentName) {
    name = potentName.toString();
  }
  Stat (String name) {
    this._name = name;
  }
}

class Attribute extends Stat {
  int base;
  bool halfRounded;
  get mod {
    if (halfRounded){
      return ((base-10)/2.0).floor();
    } else {
      return base;
    }
  }
  Attribute (String name, int base, bool halfRounded) : super(name) {
    this.base = base;
    this.halfRounded = halfRounded;
  }
}

class Skill extends Stat {
  Attribute attribute;
  int _mod;
  set mod (int newMod) {
    _mod = newMod;
  }
  get mod => _mod + attribute.mod;
  Skill (String name, Attribute attribute, int mod) : super (name) {
    this.attribute = attribute;
    this._mod = mod;
  }
}
class Pool extends Stat {
  int max;
  int _pointer;
  get pointer => _pointer;
  Pool (String name, int max) : super(name) {
    this.max = max;
    _pointer = max;
  }
  decreasePointer() {
    if (_pointer > 0){
      _pointer--;
    }
  }
  increasePointer() {
    if (_pointer < max) {
      _pointer++;
    }
  }
  resetPointer() {
    _pointer = max;
  }
}