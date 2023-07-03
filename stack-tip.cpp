#include <map>
#include <cstdio>
#include <vector>
#include <iostream>
#include <algorithm>
using namespace std;

struct funstack {
	map<string,vector<string>> m;

	void push(string fun, string line) {
		m[fun].push_back(line);
	}
	void pop(string fun) {
		m[fun].pop_back();
	}
	vector<string> get_lines() {
		vector<string> v;
		for (auto &it : m) {
			for (auto &jt : it.second) {
				v.push_back(jt);
			}
		}
		sort(v.begin(), v.end());
		return v;
	}
};

int main() {
	funstack fs;
	int line_num = 0;
	string dmesg_line;
	while (getline(cin, dmesg_line)) {
		++line_num;
		int time1, time2;
		char modname[32], fun[32], op[2];
		if (5 == sscanf(dmesg_line.c_str(), "[ %d.%6d] deco-%32[^:]: %2[-<>]%32[^:]", &time1, &time2, &modname, &op, &fun)) {
			//~ printf("%d\t[\t%d.%06d] %s %s %s\n", line_num, time1, time2, modname, op, fun);
			if (op == string("->")) {
				fs.push(fun, dmesg_line);
			} else if (op == string("<-")) {
				fs.pop(fun);
			}
		}
	}
	auto v = fs.get_lines();
	for (auto s : v) {
		cout << s << '\n';
	}
}
