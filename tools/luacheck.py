"""Basit Luau yapı denetleyicisi: parantez/süslü/köşeli ve blok (function/if/for/while/do/repeat ... end/until) dengesini kontrol eder.
Sözdizimini tam denetlemez ama eksik/fazla end ve } gibi yapısal hataları yakalar. Kullanım: python luacheck.py dosya...
"""
import io, sys, re

EXPR_PREV = {"=", "(", ",", "{", "return", "..", "+", "-", "*", "/", "and", "or", "not", "==", "~=", "<", ">", "<=", ">=", "[", "%", "^", "//", ":", "in", "+=", "-=", "*=", "/="}


def tokenize(src):
    tokens = []  # (type, value, line)
    i, n, line = 0, len(src), 1

    def read_long(i):
        # [[ ... ]] ya da [=[ ... ]=]
        m = re.match(r"\[(=*)\[", src[i:])
        if not m:
            return None
        eq = m.group(1)
        end = src.find("]" + eq + "]", i + len(m.group(0)))
        if end < 0:
            return len(src)
        return end + len(eq) + 2

    def read_interp(i):
        # backtick string with {expr} interpolations; returns (new_i, inner_tokens)
        i += 1
        inner = []
        while i < n:
            c = src[i]
            if c == "\\":
                i += 2
                continue
            if c == "`":
                return i + 1, inner
            if c == "{":
                # find matching } accounting for nested strings/braces
                depth = 1
                j = i + 1
                start = j
                while j < n and depth > 0:
                    cj = src[j]
                    if cj == "{":
                        depth += 1
                    elif cj == "}":
                        depth -= 1
                    elif cj in "\"'":
                        q = cj
                        j += 1
                        while j < n and src[j] != q:
                            if src[j] == "\\":
                                j += 1
                            j += 1
                    elif cj == "`":
                        j, _ = read_interp(j)
                        continue
                    j += 1
                inner.append(src[start:j - 1])
                i = j
                continue
            i += 1
        return n, inner

    while i < n:
        c = src[i]
        if c == "\n":
            line += 1
            i += 1
        elif c in " \t\r":
            i += 1
        elif src.startswith("--", i):
            if src.startswith("--[", i) and read_long(i + 2) is not None:
                j = read_long(i + 2)
                line += src[i:j].count("\n")
                i = j
            else:
                while i < n and src[i] != "\n":
                    i += 1
        elif c in "\"'":
            q = c
            j = i + 1
            while j < n and src[j] != q:
                if src[j] == "\\":
                    j += 1
                if src[j] == "\n":
                    line += 1
                j += 1
            tokens.append(("str", src[i:j + 1], line))
            i = j + 1
        elif c == "`":
            j, inner = read_interp(i)
            line += src[i:j].count("\n")
            tokens.append(("str", "`", line))
            # interpolation içindeki ifadeleri ayrıca denetle
            for expr in inner:
                tokens.append(("interp", expr, line))
            i = j
        elif c == "[" and read_long(i) is not None:
            j = read_long(i)
            line += src[i:j].count("\n")
            tokens.append(("str", "[[", line))
            i = j
        elif c.isalpha() or c == "_":
            j = i
            while j < n and (src[j].isalnum() or src[j] == "_"):
                j += 1
            tokens.append(("name", src[i:j], line))
            i = j
        elif c.isdigit():
            j = i
            while j < n and (src[j].isalnum() or src[j] in "._"):
                j += 1
            tokens.append(("num", src[i:j], line))
            i = j
        else:
            two = src[i:i + 2]
            if two in ("==", "~=", "<=", ">=", "..", "//", "+=", "-=", "*=", "/=", "::", "->"):
                tokens.append(("op", two, line))
                i += 2
            else:
                tokens.append(("op", c, line))
                i += 1
    return tokens


def check(path):
    src = io.open(path, encoding="utf-8").read()
    problems = []

    def run(tokens, base_line=None):
        stack = []  # (kind, line)
        prev = None
        pending_do = []  # for/while bekleyen 'do' sayısı (paren derinliğiyle)
        for kind, value, line in tokens:
            if kind == "interp":
                sub = tokenize(value)
                problems.extend(check_tokens(sub, line, path))
                continue
            if kind == "op":
                if value in "({[":
                    stack.append((value, line))
                elif value in ")}]":
                    want = {")": "(", "}": "{", "]": "["}[value]
                    if not stack or stack[-1][0] != want:
                        top = stack[-1] if stack else None
                        problems.append(f"{path}:{line}: beklenmeyen '{value}' (üstte: {top})")
                        if stack:
                            stack.pop()
                    else:
                        stack.pop()
            elif kind == "name":
                if value in ("function", "for", "while", "repeat"):
                    stack.append((value, line))
                    if value in ("for", "while"):
                        pending_do.append(len(stack))
                elif value == "do":
                    if pending_do and pending_do[-1] == len(stack):
                        pending_do.pop()  # for/while başlığının do'su
                    else:
                        stack.append(("do", line))
                elif value == "if":
                    is_expr = prev is not None and prev[1] in EXPR_PREV
                    if not is_expr:
                        stack.append(("if", line))
                elif value == "end":
                    if not stack or stack[-1][0] not in ("function", "for", "while", "do", "if"):
                        top = stack[-1] if stack else None
                        problems.append(f"{path}:{line}: fazla 'end' (üstte: {top})")
                        if stack:
                            stack.pop()
                    else:
                        stack.pop()
                elif value == "until":
                    if not stack or stack[-1][0] != "repeat":
                        problems.append(f"{path}:{line}: eşleşmeyen 'until'")
                    else:
                        stack.pop()
            prev = (kind, value)
        for kind, line in stack:
            problems.append(f"{path}:{line}: kapanmamış '{kind}'")

    def check_tokens(tokens, line, p):
        sub_problems = []
        # tek ifadeyi ayrı denetle: basit denge
        st = []
        for kind, value, ln in tokens:
            if kind == "op" and value in "({[":
                st.append(value)
            elif kind == "op" and value in ")}]":
                want = {")": "(", "}": "{", "]": "["}[value]
                if not st or st[-1] != want:
                    sub_problems.append(f"{p}:{line}: interpolasyon içinde beklenmeyen '{value}'")
                else:
                    st.pop()
        if st:
            sub_problems.append(f"{p}:{line}: interpolasyon içinde kapanmamış {st}")
        return sub_problems

    run(tokenize(src))
    return problems


if __name__ == "__main__":
    total = 0
    for path in sys.argv[1:]:
        for problem in check(path):
            print(problem)
            total += 1
    print(f"{total} sorun")
