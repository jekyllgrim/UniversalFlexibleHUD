class JGPUFH_JsonElementOrError {}

class JGPUFH_JsonElement : JGPUFH_JsonElementOrError abstract
{
	abstract string Serialize();
	abstract string GetPrettyName();
}

class JGPUFH_JsonNumber : JGPUFH_JsonElement abstract
{
	abstract JGPUFH_JsonNumber Negate();
	abstract double  asDouble();
	abstract int asInt();
	
	override string GetPrettyName()
	{
		return "Number";
	}
}

class JGPUFH_JsonInt : JGPUFH_JsonNumber
{
	int i;
	
	static JGPUFH_JsonInt make(int i = 0)
	{
		let elem = new("JGPUFH_JsonInt");
		elem.i = i;
		return elem;
	}
	override JGPUFH_JsonNumber Negate()
	{
		i = -i;
		return self;
	}
	override string Serialize()
	{
		return ""..i;
	}
	
	override double asDouble()
	{
		return double(i);
	}
	
	override int asInt()
	{
		return i;
	}
}

class JGPUFH_JsonDouble : JGPUFH_JsonNumber
{
	double d;
	
	static JGPUFH_JsonDouble Make(double d = 0)
	{
		JGPUFH_JsonDouble elem = new("JGPUFH_JsonDouble");
		elem.d = d;
		return elem;
	}
	override JGPUFH_JsonNumber Negate()
	{
		d = -d;
		return self;
	}
	override string Serialize()
	{
		return ""..d;
	}
	
	override double asDouble()
	{
		return d;
	}
	
	override int asInt()
	{
		return int(d);
	}
}

class JGPUFH_JsonBool : JGPUFH_JsonElement
{
	bool b;
	
	static JGPUFH_JsonBool Make(bool b = false)
	{
		JGPUFH_JsonBool elem = new("JGPUFH_JsonBool");
		elem.b = b;
		return elem;
	}
	
	override string Serialize()
	{
		return b? "true" : "false";
	}
	
	override string GetPrettyName()
	{
		return "Bool";
	}
}

class JGPUFH_JsonString : JGPUFH_JsonElement
{
	string s;
	
	static JGPUFH_JsonString make(string s = "")
	{
		JGPUFH_JsonString elem = new("JGPUFH_JsonString");
		elem.s=s;
		return elem;
	}
	
	override string Serialize()
	{
		return JGPUFH_JSON.serialize_string(s);
	}
	
	override string GetPrettyName()
	{
		return "String";
	}
}

class JGPUFH_JsonNull : JGPUFH_JsonElement
{
	static JGPUFH_JsonNull Make()
	{
		return new("JGPUFH_JsonNull");
	}
	
	override string Serialize()
	{
		return "null";
	}
	
	override string GetPrettyName()
	{
		return "Null";
	}
}

class JGPUFH_JsonError : JGPUFH_JsonElementOrError
{
	String what;
	
	static JGPUFH_JsonError make(string s)
	{
		JGPUFH_JsonError err = new("JGPUFH_JsonError");
		err.what = s;
		return err;
	}
}