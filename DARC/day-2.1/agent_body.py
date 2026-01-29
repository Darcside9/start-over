import requests
import subprocess
import os

COLAB_URL = "https://zywcl-34-28-50-189.a.free.pinggy.link/" # Update this every session

def execute_task(user_input):
    print(f"🧠 Consulting the Brain at Colab...")
    
    try:
        response = requests.post(f"{COLAB_URL}/generate_command", json={"prompt": user_input})
        command = response.json().get("command")
        
        print(f"\n🤖 Agent suggests: {command}")
        confirm = input("⚠️ Execute this command on your system? (y/n): ")
        
        if confirm.lower() == 'y':
            process = subprocess.run(command, shell=True, capture_output=True, text=True)
            print(f"✅ Output:\n{process.stdout}")
            if process.stderr:
                print(f"❌ Errors:\n{process.stderr}")
        else:
            print("❌ Execution cancelled.")
            
    except Exception as e:
        print(f"Error connecting to Brain: {e}")

if __name__ == "__main__":
    while True:
        task = input("\nWhat system task should I perform? (e.g., 'update system', 'find heavy files'): ")
        if task.lower() in ['exit', 'quit']: break
        execute_task(task)