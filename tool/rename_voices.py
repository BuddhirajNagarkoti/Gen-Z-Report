import os

def rename_voices():
    voices_dir = r"d:\Developer Buddhiraj\GEN Z REPORT LLM\voices"
    if not os.path.exists(voices_dir):
        print(f"Directory not found: {voices_dir}")
        return

    files = os.listdir(voices_dir)
    count = 0
    
    for filename in files:
        if filename.lower().endswith(".mp3"):
            # Original: pg X.MP3 or pg X.mp3
            # Target: pg_X.mp3
            
            # 1. Lowercase everything
            new_name = filename.lower()
            
            # 2. Replace space with underscore
            new_name = new_name.replace(" ", "_")
            
            # 3. Check if it fits the pattern pg_X.mp3
            # If it already had an underscore, this won't hurt
            
            old_path = os.path.join(voices_dir, filename)
            new_path = os.path.join(voices_dir, new_name)
            
            if old_path != new_path:
                try:
                    os.rename(old_path, new_path)
                    print(f"Renamed: {filename} -> {new_name}")
                    count += 1
                except Exception as e:
                    print(f"Error renaming {filename}: {e}")

    print(f"\nSuccessfully renamed {count} voice files.")

if __name__ == "__main__":
    rename_voices()
