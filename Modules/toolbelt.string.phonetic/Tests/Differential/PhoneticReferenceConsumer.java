import java.io.InputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import org.apache.commons.codec.language.ColognePhonetic;
import org.apache.commons.codec.language.DoubleMetaphone;

// Privater Aufruf unveraenderter Originalklassen, kein Ersatzscanner.
public final class PhoneticReferenceConsumer {
    private static final class Item {
        int id;
        String algorithm;
        String text;
    }
    private static void need(boolean value) {
        if (!value) throw new IllegalStateException("PHONETIC_DIFFERENTIAL_REFERENCE_SHAPE");
    }
    private static byte[] corpusBytes(String path) throws IOException {
        byte[] buffer = new byte[32769];
        int count = 0;
        try (InputStream stream = Files.newInputStream(Paths.get(path))) {
            while (count < buffer.length) {
                int read = stream.read(buffer, count, buffer.length - count);
                if (read < 0) break;
                need(read > 0);
                count += read;
            }
        }
        need(count > 0 && count <= 32768);
        byte[] result = new byte[count];
        System.arraycopy(buffer, 0, result, 0, count);
        return result;
    }
    private static void pin(byte[] bytes, String expected) throws Exception {
        need(expected != null && expected.matches("[0-9A-F]{64}"));
        byte[] digest = MessageDigest.getInstance("SHA-256").digest(bytes);
        StringBuilder hex = new StringBuilder();
        final String digits = "0123456789ABCDEF";
        for (byte value : digest) {
            hex.append(digits.charAt((value & 255) >>> 4));
            hex.append(digits.charAt(value & 15));
        }
        need(hex.toString().equals(expected));
    }
    private static List<Item> corpus(byte[] bytes) {
        for (byte value : bytes) {
            int b = value & 255;
            need(b == 9 || b == 10 || b >= 32 && b <= 126);
        }
        String[] lines = new String(bytes, StandardCharsets.US_ASCII).split("\n", -1);
        need(lines.length >= 3 && lines.length <= 66 && lines[0].equals("PHONETIC_CORPUS_V1") && lines[lines.length - 1].equals(""));
        List<Item> items = new ArrayList<>();
        boolean aj = false;
        for (int i = 1; i < lines.length - 1; i++) {
            String[] fields = lines[i].split("\t", -1);
            need(fields.length == 3 && fields[0].equals(Integer.toString(i)));
            need(fields[1].equals("C") || fields[1].equals("D"));
            byte[] raw = Base64.getDecoder().decode(fields[2]);
            need(Base64.getEncoder().encodeToString(raw).equals(fields[2]) && raw.length >= 2 && raw.length <= 256 && raw.length % 2 == 0);
            char[] chars = new char[raw.length / 2];
            boolean core = false;
            for (int j = 0; j < chars.length; j++) {
                char ch = (char)((raw[2 * j] & 255) | (raw[2 * j + 1] & 255) << 8);
                String extra = fields[1].equals("C") ? "\u00C4\u00D6\u00DC\u00E4\u00F6\u00FC\u00DF" : "\u00C7\u00E7\u00D1\u00F1";
                need(ch <= 127 || extra.indexOf(ch) >= 0);
                chars[j] = ch;
                core |= ch > 32;
            }
            need(fields[1].equals("C") || core);
            Item item = new Item();
            item.id = i; item.algorithm = fields[1]; item.text = new String(chars);
            aj |= item.algorithm.equals("D") && item.text.equals("AJ");
            items.add(item);
        }
        need(items.size() >= 1 && items.size() <= 64 && aj);
        return items;
    }
    private static byte[] code(String value) {
        need(value != null && value.length() <= 16384);
        for (int i = 0; i < value.length(); i++) need(value.charAt(i) <= 127);
        return value.getBytes(StandardCharsets.US_ASCII);
    }
    public static void main(String[] args) {
        try {
            need(args.length == 2);
            byte[] bytes = corpusBytes(args[0]);
            pin(bytes, args[1]);
            List<Item> items = corpus(bytes);
            ColognePhonetic cologne = new ColognePhonetic();
            DoubleMetaphone metaphone = new DoubleMetaphone();
            // Der Originalsetter hat keine Validierung; dieser Consumer waehlt fest den Fullcodevertrag.
            metaphone.setMaxCodeLen(16384);
            need(metaphone.getMaxCodeLen() == 16384);
            StringBuilder output = new StringBuilder("PHONETIC_DIFFERENTIAL_V1\n");
            for (Item item : items) {
                byte[] primary;
                byte[] alternate = null;
                if (item.algorithm.equals("C")) {
                    primary = code(cologne.colognePhonetic(item.text));
                } else {
                    primary = code(metaphone.doubleMetaphone(item.text, false));
                    alternate = code(metaphone.doubleMetaphone(item.text, true));
                    need(primary.length + alternate.length <= 32768);
                }
                output.append(item.id).append('\t').append(item.algorithm).append("\t-\t")
                    .append(primary.length).append('\t').append(Base64.getEncoder().encodeToString(primary)).append('\t');
                if (alternate == null) output.append("-1\t-");
                else output.append(alternate.length).append('\t').append(Base64.getEncoder().encodeToString(alternate));
                output.append('\n');
            }
            // Ausgabe erst nach vollstaendigem Erfolg, ohne Trim oder Codepraefix.
            byte[] wire = output.toString().getBytes(StandardCharsets.US_ASCII);
            System.out.write(wire);
            System.out.flush();
            need(!System.out.checkError());
        } catch (Exception failure) {
            System.err.println("PHONETIC_DIFFERENTIAL_REFERENCE_FAILED");
            System.exit(1);
        }
    }
}
