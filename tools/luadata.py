"""Parse a Lua table *literal* (data only, nothing is executed).

Supports: { }, [key] = value, name = value, positional values, numbers (incl. hex,
negative, floats, exponents), short strings ('..' / ".." with escapes), long strings
[[..]] / [==[..]==], nil / true / false, and -- comments.
Positional arrays are returned as dict {1: v1, 2: v2, ...} so holes (nil) are kept.
"""
import re

_num = re.compile(r"-?(?:0[xX][0-9a-fA-F]+|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)")
_name = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
_ws = re.compile(r"(?:\s+|--\[(=*)\[.*?\]\1\]|--[^\n]*)+", re.S)
_esc = {"n": "\n", "t": "\t", "r": "\r", "\\": "\\", '"': '"', "'": "'", "\n": "\n", "a": "\a", "b": "\b", "f": "\f", "v": "\v"}

NIL = None


class Parser:
    def __init__(self, s):
        self.s, self.i, self.n = s, 0, len(s)

    def ws(self):
        m = _ws.match(self.s, self.i)
        if m:
            self.i = m.end()

    def peek(self):
        self.ws()
        return self.s[self.i] if self.i < self.n else ""

    def expect(self, c):
        self.ws()
        if self.s[self.i] != c:
            raise ValueError("expected %r at %d, got %r" % (c, self.i, self.s[self.i:self.i + 30]))
        self.i += 1

    def long_string(self):
        m = re.compile(r"\[(=*)\[").match(self.s, self.i)
        eq = m.group(1)
        end = self.s.index("]" + eq + "]", m.end())
        val = self.s[m.end():end]
        if val.startswith("\n"):
            val = val[1:]
        self.i = end + len(eq) + 2
        return val

    def short_string(self):
        q = self.s[self.i]
        self.i += 1
        out = []
        while True:
            c = self.s[self.i]
            if c == q:
                self.i += 1
                return "".join(out)
            if c == "\\":
                nxt = self.s[self.i + 1]
                if nxt.isdigit():
                    m = re.compile(r"\d{1,3}").match(self.s, self.i + 1)
                    out.append(chr(int(m.group(0))))
                    self.i = m.end()
                    continue
                out.append(_esc.get(nxt, nxt))
                self.i += 2
                continue
            out.append(c)
            self.i += 1

    def value(self):
        c = self.peek()
        if c == "{":
            return self.table()
        if c in "\"'":
            return self.short_string()
        if c == "[" and re.compile(r"\[=*\[").match(self.s, self.i):
            return self.long_string()
        m = _num.match(self.s, self.i)
        if m:
            self.i = m.end()
            t = m.group(0)
            if "x" in t.lower():
                return int(t, 16)
            return float(t) if any(ch in t for ch in ".eE") else int(t)
        m = _name.match(self.s, self.i)
        if m:
            self.i = m.end()
            w = m.group(0)
            if w == "nil":
                return NIL
            if w == "true":
                return True
            if w == "false":
                return False
            raise ValueError("unexpected identifier %r at %d" % (w, self.i))
        raise ValueError("unexpected %r at %d" % (self.s[self.i:self.i + 30], self.i))

    def table(self):
        self.expect("{")
        t, idx = {}, 1
        while True:
            c = self.peek()
            if c == "}":
                self.i += 1
                return t
            if c == "[" and not re.compile(r"\[=*\[").match(self.s, self.i):
                self.i += 1
                k = self.value()
                self.expect("]")
                self.expect("=")
                t[k] = self.value()
            else:
                m = _name.match(self.s, self.i)
                save = self.i
                if m and m.group(0) not in ("nil", "true", "false"):
                    self.i = m.end()
                    if self.peek() == "=" and self.s[self.i + 1:self.i + 2] != "=":
                        self.i += 1
                        t[m.group(0)] = self.value()
                    else:
                        self.i = save
                        v = self.value()
                        if v is not NIL:
                            t[idx] = v
                        idx += 1
                else:
                    v = self.value()
                    if v is not NIL:
                        t[idx] = v
                    idx += 1
            c = self.peek()
            if c in ",;":
                self.i += 1


def parse_return_table(src):
    """Parse `return { ... }`."""
    p = Parser(src)
    p.ws()
    if src.startswith("return", p.i):
        p.i += 6
    return p.value()


def extract_assigned_string(file_text, var):
    """Find `var = [[ ... ]]` and return the inner string."""
    m = re.search(re.escape(var) + r"\s*=\s*\[(=*)\[", file_text)
    if not m:
        raise KeyError(var)
    eq = m.group(1)
    start = m.end()
    end = file_text.index("]" + eq + "]", start)
    return file_text[start:end]


def extract_assigned_table(file_text, var):
    m = re.search(re.escape(var) + r"\s*=\s*\{", file_text)
    p = Parser(file_text)
    p.i = m.end() - 1
    return p.value()
