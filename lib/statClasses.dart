import "dart:math";
import "dart:convert";

class Stat {
  var name;
  Stat(String name) {
    this.name = name;
  }
  Stat.fromJson(Map<String, dynamic> json) {
    this.name = json["name"];
  }
  Map<String, dynamic> toJson() => {
    "name" : name,
  };
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
  Attribute(String name, int base, bool halfRounded) : super(name) {
    this.base = base;
    this.halfRounded = halfRounded;
  }
  Attribute.fromAttr(Attribute attribute) : super(attribute.name) {
    this.base = attribute.base;
    this.halfRounded = attribute.halfRounded;
  }
  Attribute.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.base = json["base"];
    this.halfRounded = json["halfRounded"];
  }
  Map<String, dynamic> toJson() => {
    "name" : name,
    "base" : base,
    "halfRounded" : halfRounded
  };
}

class Skill extends Stat {
  String relatedAttribute;
  int mod;
  Skill(String name, String attributeName, int mod) : super (name) {
    this.relatedAttribute = attributeName;
    this.mod = mod;
  }
  Skill.fromSkill(Skill copy) : super (copy.name) {
    this.relatedAttribute = copy.relatedAttribute;
    this.mod = mod;
  }

  Skill.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.relatedAttribute = json["relatedAttribute"];
    this.mod = json["mod"];
  }
  Map<String, dynamic> toJson() => {
    "name" : name,
    "relatedAttribute" : relatedAttribute,
    "mod" : mod
  };
}
class Pool extends Stat {
  int max;
  int _pointer;
  get pointer => _pointer;
  Pool(String name, int max) : super(name) {
    this.max = max;
    _pointer = max;
  }
  Pool.fromPool(Pool copy) : super(copy.name){
    this.max = copy.max;
    _pointer = copy.pointer;
  }
  Pool.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.max = json["max"];
    this._pointer = json["pointer"];
  }
  decreasePointer([int amount]) {
    for (amount ??= 1; amount>0; amount--) {
      if (_pointer > 0) {
        _pointer--;
      }
    }
  }
  increasePointer([int amount]) {
    for (amount ??=1; amount > 0; amount--) {
      if (_pointer < max) {
        _pointer++;
      }
    }
  }
  resetPointer() {
    _pointer = max;
  }
  Map<String, dynamic> toJson() => {
    "name" : name,
    "max" : max,
    "pointer" : pointer
  };
}

class Character {
  String name;
  Map<String, Attribute> attrs = {};
  Map<String, Skill> skills = {};
  Map<String, Pool> pools = {};
  var randoms;
  
  Character (String name, Map<String, Stat> importStats) {
    this.name = name;
    importStats.forEach((key, value)  {
      if (value is Attribute) {
        attrs[key] = value;
      }
      else if (value is Skill) {
        skills[key] = value;
      }
      else if (value is Pool) {
        pools[key] = value;
      }
    });
    if (!pools.containsKey("HP")){
      pools["HP"] = new Pool("HP", 10);
    }
    randoms = new Random(new DateTime.now().millisecondsSinceEpoch);
  }

  Character.fromJson(Map<String, dynamic> json) {
    var attrs = {};
    var skills = {};
    var pools = {};
    json["attributes"].forEach((key, value) {
      attrs[key] = Pool.fromJson(value);
    });
    json["skills"].forEach((key, value) {
      skills[key] = Pool.fromJson(value);
    });
    json["pools"].forEach((key, value) {
      pools[key] = Pool.fromJson(value);
    });
    this.name = json["name"];
    this.attrs = attrs;
    this.skills = skills;
    this.pools = pools;
  }

  int makeSkillRoll(int dNum, String skillKey) => skills[skillKey].mod + makeAttrRoll(dNum, skills[skillKey].relatedAttribute);

  int makeAttrRoll(int dNum, String attrKey) => attrs[attrKey].mod + makeRoll(dNum);

  int makeRoll(int dNum) => randoms.nextInt(dNum) + 1;

  Map<String, dynamic> toJson() {
     var attrMap = {};
     var skillMap = {};
     var poolMap = {};
     attrs.forEach((key, value) {
       attrMap[key] = value.toJson();
     });
     skills.forEach((key, value) {
       skillMap[key] = value.toJson();
     });
     pools.forEach((key, value) {
       poolMap[key] = value.toJson();
     });
     return {
       "name": name,
       "attributes": attrMap,
       "skills": skillMap,
       "pools": poolMap,
    };
  }
}

void main() {
  Character myChar = new Character("jeff", {
    "strength": new Attribute("strength", 18, false),
    "running": new Skill("running", "strength", 2)
  });
  var myCharMap = myChar.toJson();
  var charString = jsonEncode(myCharMap);
  Character newChar = new Character.fromJson(jsonDecode(charString));
  print(newChar.name);
}