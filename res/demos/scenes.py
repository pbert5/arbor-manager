# Each step specifies input, visible keys, reader caption, and required screen text.
TOURS = {
    "overview": [
        ("", "Open Overview", "Five machines are selected. Two are excluded. The snapshot has two roots.", "SNAPSHOT OVERVIEW"),
        ("j", "j", "Move down to Registry to see how many records the projection supplies.", "supplied records"),
        ("\n", "Enter", "Open Registry directly from its summary row.", "REGISTRY PROJECTION"),
        ("1", "1", "Jump back to the dashboard. The Plan row shows the backend and phase count.", "SNAPSHOT OVERVIEW"),
        ("jjj\n", "j × 3 · Enter", "Open Plan to see the two phases behind that count.", "DEPLOYMENT PLAN"),
    ],
    "nodes": [
        ("", "Open Nodes", "Scan machine platforms and lifecycle states across the inventory.", "NODE INVENTORY"),
        ("/cedar\n", "/ cedar · Enter", "Filter by machine name to locate Cedar.", "Filter: cedar"),
        ("\n", "Enter", "Read Cedar’s hostname, source, and declared relationships.", "cedar.example"),
        ("g", "g", "Open the relationship explorer with Cedar already in focus.", "FOCUS   cedar"),
    ],
    "registry": [
        ("", "Open Registry", "Browse the IDs, schemas, and generations in the supplied projection.", "REGISTRY PROJECTION"),
        ("\n", "Enter", "Open the Atlas identity record to read its generation.", "RECORD METADATA"),
        ("\x1b", "Esc", "Return to the projected records.", "REGISTRY PROJECTION"),
        ("/birch-cedar\n", "/ birch-cedar · Enter", "Find the record connecting Birch and Cedar.", "Filter: birch-cedar"),
        ("\n", "Enter", "Read the direction and standby status attached to this relationship.", "standby"),
    ],
    "network": [
        ("", "Open Network", "Start at Atlas. Its snapshot declares Cedar and Spruce as children.", "FOCUS   atlas"),
        ("\n", "Enter", "Follow Cedar. Atlas and Birch are its parents, and Moss is its child.", "FOCUS   cedar"),
        ("jj\n", "j × 2 · Enter", "Follow the child to Moss. The trail shows the path you took.", "FOCUS   moss"),
        ("\x1b", "Esc", "Retrace one step to Cedar.", "FOCUS   cedar"),
        ("s", "s", "Compare the projection. Birch is on standby and Spruce appears as a peer.", "standby"),
        ("jjj\n", "j × 3 · Enter", "Follow the peer to Spruce and inspect its other incident links.", "FOCUS   spruce"),
        ("n", "n", "Open the directory to find nodes outside the current neighbourhood.", "isle"),
        ("/isle\n", "/ isle · Enter", "Narrow the directory to Isle.", "Filter: isle"),
        ("\n", "Enter", "Isle has an identity but no incident links in this source.", "No incident links"),
        ("e", "e", "Check the fictional endpoint counts independently of the topology.", "Observed records"),
    ],
    "plan": [
        ("", "Open Plan", "Start with the direct backend’s canary and batch phases.", "DEPLOYMENT PLAN"),
        ("\n", "Enter", "Read the canary membership. Atlas is first in the rollout.", "atlas"),
        ("\x1b", "Esc", "Return to the ordered phases.", "DEPLOYMENT PLAN"),
        ("j", "j", "Select the phase containing the two rollout batches.", "batches"),
        ("\n", "Enter", "Read both groups: Birch and Cedar precede Spruce and Moss.", "Batch 2"),
    ],
}
