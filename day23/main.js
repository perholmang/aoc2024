const fs = require("fs");
const data = fs.readFileSync("./input.txt", {
  encoding: "utf8",
  flag: "r",
});

const lines = data.split("\n");

const sets = {};
for (let i = 0; i < lines.length; i++) {
  const [lft, rgt] = lines[i].split("-");
  if (sets[lft] === undefined) {
    sets[lft] = new Set();
  }
  sets[lft].add(rgt);

  if (sets[rgt] === undefined) {
    sets[rgt] = new Set();
  }
  sets[rgt].add(lft);
}

const keys = Object.keys(sets);

function bronKerbosch(nodes) {
  var maxR = [];

  function bronKerbosch(r, p, x) {
    if (p.length === 0 && x.length === 0) {
      //console.log(r);
      if (r.length > maxR.length) {
        maxR = r;
      }
    }

    for (let i = 0; i < p.length; i++) {
      const v = p[i];
      //const [a, b] = p[i];
      const newR = [...r, v];
      const newP = p.filter((e) => sets[v].has(e));
      const newX = x.filter((e) => sets[v].has(e));
      bronKerbosch(newR, newP, newX);
      p = p.filter((e) => e !== v);
      x = [...x, v];
    }
  }

  bronKerbosch([], nodes, []);

  return maxR;
}

function findCliquesOfSize3(sets, keys) {
  const k3cliques = new Set();

  for (let i = 0; i < keys.length; i++) {
    for (let j = 0; j < keys.length; j++) {
      for (let k = 0; k < keys.length; k++) {
        if (i === j || j === k || i === k) {
          continue;
        }

        const [a, b, c] = [keys[i], keys[j], keys[k]];
        if (sets[a].has(b) && sets[b].has(c) && sets[c].has(a)) {
          if (a.startsWith("t") || b.startsWith("t") || c.startsWith("t")) {
            const key = [a, b, c].sort().join("-");
            k3cliques.add(key);
          }
        }
      }
    }
  }
  return k3cliques;
}

if (process.env.part === "part1") {
  const k3cliques = findCliquesOfSize3(sets, keys);
  console.log(k3cliques.size);
} else {
  const cliques = bronKerbosch(Object.keys(sets));
  console.log(cliques.sort().join(","));
}
