/* LoaderCheck.java - Resolution-only smoke tester for Fabric mod jars.
 * Reports: missing required dependencies, classfile version too new for the running JVM,
 *          malformed fabric.mod.json.
 * Does NOT launch Minecraft or Fabric Loader. Pure JSON output to stdout.
 *
 * Build (one-time): javac --release 17 scripts/LoaderCheck.java -d .test/cf-loader-check/
 *                   jar --create --file .test/cf-loader-check/LoaderCheck.jar --main-class LoaderCheck -C .test/cf-loader-check/ .
 * Run:              java -jar .test/cf-loader-check/LoaderCheck.jar <path-to-mods-dir>
 */
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import java.util.jar.*;
import java.util.zip.*;

public class LoaderCheck {

    // mixinextras is bundled by Fabric Loader 0.15+ as a built-in library, not a separate mod jar
    static final Set<String> INTRINSIC = Set.of("minecraft", "fabricloader", "java", "fabric-loader", "mixinextras");

    public static void main(String[] args) throws Exception {
        if (args.length < 1) { System.err.println("usage: java -jar LoaderCheck.jar <mods-dir>"); System.exit(2); }
        Path modsDir = Path.of(args[0]);
        if (!Files.isDirectory(modsDir)) { System.err.println("not a directory: " + modsDir); System.exit(2); }

        int jvmMajor = jvmMajor();

        List<Map<String, Object>> issues = new ArrayList<>();
        Map<String, ModInfo> mods = new LinkedHashMap<>();

        // Collect IDs provided by nested JARs (META-INF/jars/*.jar inside each mod jar)
        Set<String> nestedModIds = new HashSet<>();
        for (Path jar : sortedJars(modsDir)) {
            collectNestedModIds(jar, nestedModIds);
        }

        for (Path jar : sortedJars(modsDir)) {
            ModInfo m = parseMod(jar, issues);
            if (m != null) {
                mods.put(m.id, m);
                int needed = classFileMajor(jar);
                if (needed > jvmMajor) {
                    issues.add(issue(m.id, jar.getFileName().toString(),
                        "class-file-version-too-new",
                        "needs JVM major " + needed + ", running " + jvmMajor));
                }
            }
        }

        // Collect all virtual IDs declared via "provides" across every mod
        Set<String> provided = new HashSet<>();
        for (ModInfo m : mods.values()) provided.addAll(m.provides);
        provided.addAll(nestedModIds);

        for (ModInfo m : mods.values()) {
            for (String dep : m.depends) {
                if (INTRINSIC.contains(dep)) continue;
                if (!mods.containsKey(dep) && !provided.contains(dep)) {
                    issues.add(issue(m.id, m.jarName, "missing-required-dependency", dep));
                }
            }
        }

        Map<String, Object> root = new LinkedHashMap<>();
        root.put("ok", issues.isEmpty());
        root.put("jvm_major", jvmMajor);
        root.put("scanned_mods", new ArrayList<>(mods.keySet()));
        root.put("issues", issues);
        System.out.println(toJson(root));
    }

    static int jvmMajor() {
        try (InputStream in = Object.class.getResourceAsStream("/java/lang/Object.class")) {
            if (in == null) return -1;
            byte[] head = in.readNBytes(8);
            int major = ((head[6] & 0xFF) << 8) | (head[7] & 0xFF);
            return major;
        } catch (IOException e) { return -1; }
    }

    static int classFileMajor(Path jar) {
        try (ZipFile zf = new ZipFile(jar.toFile())) {
            Enumeration<? extends ZipEntry> e = zf.entries();
            while (e.hasMoreElements()) {
                ZipEntry ze = e.nextElement();
                if (ze.getName().endsWith(".class") && !ze.getName().contains("META-INF/")) {
                    try (InputStream in = zf.getInputStream(ze)) {
                        byte[] head = in.readNBytes(8);
                        if (head.length < 8) continue;
                        return ((head[6] & 0xFF) << 8) | (head[7] & 0xFF);
                    }
                }
            }
        } catch (IOException ignored) {}
        return -1;
    }

    static ModInfo parseMod(Path jar, List<Map<String, Object>> issues) {
        try (ZipFile zf = new ZipFile(jar.toFile())) {
            ZipEntry entry = zf.getEntry("fabric.mod.json");
            if (entry == null) {
                issues.add(issue("?", jar.getFileName().toString(), "no-fabric-mod-json",
                    "jar does not declare fabric.mod.json"));
                return null;
            }
            String content;
            try (InputStream in = zf.getInputStream(entry)) {
                content = new String(in.readAllBytes(), StandardCharsets.UTF_8);
            }
            String id = jsonString(content, "id");
            if (id == null) {
                issues.add(issue("?", jar.getFileName().toString(), "malformed-fabric-mod-json",
                    "missing \"id\" field"));
                return null;
            }
            Set<String> deps = parseDependsKeys(content);
            Set<String> prov = parseProvidesArray(content);
            return new ModInfo(id, jar.getFileName().toString(), deps, prov);
        } catch (IOException e) {
            issues.add(issue("?", jar.getFileName().toString(), "io-error", e.getMessage()));
            return null;
        }
    }

    static String jsonString(String src, String key) {
        String needle = "\"" + key + "\"";
        int i = src.indexOf(needle);
        if (i < 0) return null;
        int colon = src.indexOf(':', i + needle.length());
        if (colon < 0) return null;
        int start = src.indexOf('"', colon);
        if (start < 0) return null;
        int end = src.indexOf('"', start + 1);
        if (end < 0) return null;
        return src.substring(start + 1, end);
    }

    static Set<String> parseDependsKeys(String src) {
        Set<String> out = new LinkedHashSet<>();
        int i = src.indexOf("\"depends\"");
        if (i < 0) return out;
        int open = src.indexOf('{', i);
        if (open < 0) return out;
        int depth = 0, cursor = open;
        while (cursor < src.length()) {
            char c = src.charAt(cursor);
            if (c == '{') { depth++; cursor++; continue; }
            if (c == '}') { depth--; if (depth == 0) break; cursor++; continue; }
            if (c == '"' && depth == 1) {
                // Read the key name
                int e = src.indexOf('"', cursor + 1);
                if (e < 0) break;
                String key = src.substring(cursor + 1, e);
                out.add(key);
                cursor = e + 1;
                // Skip colon
                while (cursor < src.length() && src.charAt(cursor) != ':') cursor++;
                cursor++; // past ':'
                // Skip the value character-by-character, tracking depth and strings,
                // so we never jump past the closing '}' of the depends object.
                int vDepth = 0;
                boolean inStr = false;
                while (cursor < src.length()) {
                    char v = src.charAt(cursor);
                    if (inStr) {
                        if (v == '\\') cursor++; // skip escaped char
                        else if (v == '"') inStr = false;
                    } else if (v == '"') {
                        inStr = true;
                    } else if (v == '{' || v == '[') {
                        vDepth++;
                    } else if (v == '}' || v == ']') {
                        if (vDepth == 0) break; // closing brace belongs to parent — leave for outer loop
                        vDepth--;
                    } else if (v == ',' && vDepth == 0) {
                        cursor++; break; // past the separator, ready for next key
                    }
                    cursor++;
                }
                continue;
            }
            cursor++;
        }
        return out;
    }

    static void collectNestedModIds(Path outerJar, Set<String> out) {
        try (ZipFile zf = new ZipFile(outerJar.toFile())) {
            Enumeration<? extends ZipEntry> entries = zf.entries();
            while (entries.hasMoreElements()) {
                ZipEntry ze = entries.nextElement();
                String name = ze.getName();
                if (!name.startsWith("META-INF/jars/") || !name.endsWith(".jar")) continue;
                try (InputStream jarStream = zf.getInputStream(ze)) {
                    byte[] bytes = jarStream.readAllBytes();
                    try (ZipFile inner = new ZipFile(createTempJar(bytes))) {
                        ZipEntry fmj = inner.getEntry("fabric.mod.json");
                        if (fmj == null) continue;
                        try (InputStream in = inner.getInputStream(fmj)) {
                            String content = new String(in.readAllBytes(), StandardCharsets.UTF_8);
                            String id = jsonString(content, "id");
                            if (id != null) {
                                out.add(id);
                                out.addAll(parseProvidesArray(content));
                            }
                        }
                    } catch (IOException ignored) {}
                } catch (IOException ignored) {}
            }
        } catch (IOException ignored) {}
    }

    static java.io.File createTempJar(byte[] bytes) throws IOException {
        java.io.File tmp = java.io.File.createTempFile("lc-nested-", ".jar");
        tmp.deleteOnExit();
        try (java.io.FileOutputStream fos = new java.io.FileOutputStream(tmp)) { fos.write(bytes); }
        return tmp;
    }

    static Set<String> parseProvidesArray(String src) {
        Set<String> out = new LinkedHashSet<>();
        int i = src.indexOf("\"provides\"");
        if (i < 0) return out;
        int open = src.indexOf('[', i);
        if (open < 0) return out;
        int cursor = open + 1;
        while (cursor < src.length()) {
            char c = src.charAt(cursor);
            if (c == ']') break;
            if (c == '"') {
                int e = src.indexOf('"', cursor + 1);
                if (e < 0) break;
                out.add(src.substring(cursor + 1, e));
                cursor = e + 1;
                continue;
            }
            cursor++;
        }
        return out;
    }

    static Map<String,Object> issue(String modId, String jarName, String code, String detail) {
        Map<String,Object> m = new LinkedHashMap<>();
        m.put("mod_id", modId);
        m.put("jar", jarName);
        m.put("code", code);
        m.put("detail", detail);
        return m;
    }

    static List<Path> sortedJars(Path dir) throws IOException {
        try (var s = Files.list(dir)) {
            return s.filter(p -> p.toString().endsWith(".jar")).sorted().toList();
        }
    }

    record ModInfo(String id, String jarName, Set<String> depends, Set<String> provides) {}

    static String toJson(Object o) {
        StringBuilder sb = new StringBuilder();
        writeJson(o, sb);
        return sb.toString();
    }
    @SuppressWarnings("unchecked")
    static void writeJson(Object o, StringBuilder sb) {
        if (o == null) { sb.append("null"); return; }
        if (o instanceof Boolean || o instanceof Number) { sb.append(o); return; }
        if (o instanceof String s) { sb.append('"').append(s.replace("\\","\\\\").replace("\"","\\\"")).append('"'); return; }
        if (o instanceof List<?> l) {
            sb.append('[');
            for (int i = 0; i < l.size(); i++) { if (i>0) sb.append(','); writeJson(l.get(i), sb); }
            sb.append(']'); return;
        }
        if (o instanceof Map<?,?> m) {
            sb.append('{');
            int i = 0;
            for (Map.Entry<?,?> e : m.entrySet()) {
                if (i++ > 0) sb.append(',');
                writeJson(e.getKey().toString(), sb);
                sb.append(':');
                writeJson(e.getValue(), sb);
            }
            sb.append('}'); return;
        }
        sb.append('"').append(o).append('"');
    }
}
