public class Main {
	public static void main(String[] args) {
		Message m = new FormalIncognitoMessage("SillyFreak", "World", "Hello.");
		m.send();

		// Dear World,
		// Hello.
		// Sincerely, SillyFreak
	}
}

class Message {
  private final String sender, receiver, content;

	public Message(String sender, String receiver, String content) {
		this.sender = sender;
		this.receiver = receiver;
		this.content = content;
	}

	public String getSender() {
		return sender;
	}

	public String getReceiver() {
		return receiver;
	}

	public String getContent() {
		return content;
	}

  public void send() {
    System.out.println(getContent());
  }
}

class FormalMessage extends Message {
	public FormalMessage(String sender, String receiver, String content) {
		super(sender, receiver, content);
	}

  @Override
  public void send() {
    System.out.println("Dear " + super.getReceiver() + ",");
    super.send();
    System.out.println("Sincerely, " + super.getSender());
  }
}

class FormalIncognitoMessage extends FormalMessage {
	public FormalIncognitoMessage(String sender, String receiver, String content) {
		super(sender, receiver, content);
	}

  @Override
  public String getSender() {
    return "Anonymous";
  }
}
