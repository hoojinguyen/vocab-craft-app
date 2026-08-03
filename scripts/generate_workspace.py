import os

def create_workspace():
    os.makedirs("VocabCraft.xcworkspace", exist_ok=True)
    workspace_data = """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "group:VocabCraftApp.xcodeproj">
   </FileRef>
</Workspace>
"""
    with open("VocabCraft.xcworkspace/contents.xcworkspacedata", "w") as f:
        f.write(workspace_data)
    print("VocabCraft.xcworkspace created successfully!")

if __name__ == "__main__":
    create_workspace()
