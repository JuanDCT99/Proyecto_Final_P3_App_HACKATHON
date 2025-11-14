import javax.swing.JOptionPane;

public class Mensaje {
    public static void main(String[] args) {
        // JOptionPane.showMessageDialog(null, args[0]);

        if (args.length > 0 && args[0].equals("input")) {
            String message = args[1];
            String input = JOptionPane.showInputDialog(null, message);

            System.out.println(input);
        } else if (args.length > 0){
            JOptionPane.showMessageDialog(null, args[0]);
        }else {
            JOptionPane.showMessageDialog(null, "No message provided.");
        }
    }
}