"""Write the Spoken Pages Wwise work units from rendered book wavs."""

import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOICES = ROOT / "voices"
PROJECT = ROOT / "wwise" / "spokenpages"
MANIFEST = VOICES / "book-audio.jsonl"
WAV_DIR = PROJECT / "Originals" / "SFX" / "books"
SKIP_SCRIPT = False
SEED = 20261025
ACTOR = PROJECT / "Actor-Mixer Hierarchy" / "Default Work Unit.wwu"
EVENTS = PROJECT / "Events" / "Default Work Unit.wwu"
BANK = PROJECT / "SoundBanks" / "Default Work Unit.wwu"
SCRIPT = ROOT / "mod" / "modSpokenPages" / "content" / "scripts" / "local" / "modSpokenPagesBooks.ws"

ACTOR_WU = "{DB563B3A-12FA-4C8B-B1D1-D267D394A229}"
EVENT_WU = "{E7FB85FE-37FB-414D-BB29-6D0DA3076B1A}"
BANK_WU = "{EB38BBF7-873D-4563-958C-2E659DD3E620}"
BANK_ID = "{C3A91F70-2D44-4B8E-9A16-7E5B0C88D412}"
CONV = "{6D1B890C-9826-4384-BF07-C15223E9FB56}"
CONV_WU = "{7B7E6582-4991-473D-8A2A-B9BC60F6BE0C}"
BUS = "{1514A4D8-1DA6-412A-A17E-75CA0C2149F3}"
BUS_WU = "{4AFF7A7E-A5A9-40E0-A5B6-F361410EE586}"
PARAM = "{B1A7C3E0-4D21-4A88-9F10-6C2E8A11D030}"
PARAM_WU = "{C76B5436-0018-437D-91EF-A4CA8985EDE7}"
MIXER = "{A7C31E20-6B44-4F18-9A16-7E5B0C88D700}"

def next_id(rng: random.Random, used: set) -> int:
    while True:
        value = rng.randrange(1, 2**31 - 1)
        if value not in used:
            used.add(value)
            return value


def guid(rng: random.Random) -> str:
    raw = rng.getrandbits(128)
    # RFC variant bits, enough for Wwise which only needs uniqueness.
    return "{%08X-%04X-%04X-%04X-%012X}" % (
        (raw >> 96) & 0xFFFFFFFF,
        (raw >> 80) & 0xFFFF,
        ((raw >> 64) & 0x0FFF) | 0x4000,
        ((raw >> 48) & 0x3FFF) | 0x8000,
        raw & 0xFFFFFFFFFFFF,
    )


def load_rows():
    rows = []
    seen = set()
    for line in MANIFEST.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        if row["name"] in seen:
            continue
        wav = WAV_DIR / row["file"]
        if not wav.exists():
            continue
        seen.add(row["name"])
        rows.append(row)
    rows.sort(key=lambda row: row["name"].lower())
    return rows


def sound_xml(row, ids) -> str:
    sound_id = ids["sound"]
    source_id = ids["source"]
    return f"""
				<Sound Name="{row['event']}" ID="{sound_id}" ShortID="{ids['sound_short']}">
					<PropertyList/>
					<ReferenceList>
						<Reference Name="Conversion">
							<ObjectRef Name="Default Conversion Settings" ID="{CONV}" WorkUnitID="{CONV_WU}"/>
						</Reference>
						<Reference Name="OutputBus">
							<ObjectRef Name="Master Audio Bus" ID="{BUS}" WorkUnitID="{BUS_WU}"/>
						</Reference>
					</ReferenceList>
					<ChildrenList>
						<AudioFileSource Name="{row['event']}" ID="{source_id}">
							<Language>SFX</Language>
							<AudioFile>books/{row['file']}</AudioFile>
							<MediaIDList>
								<MediaID ID="{ids['media']}"/>
							</MediaIDList>
						</AudioFileSource>
					</ChildrenList>
					<ObjectLists>
						<ObjectList Name="RTPC">
							<Reference>
								<Local>
									<RTPC Name="" ID="{ids['rtpc']}" ShortID="{ids['rtpc_short']}">
										<PropertyList>
											<Property Name="PropertyName" Type="string" Value="Volume"/>
										</PropertyList>
										<ReferenceList>
											<Reference Name="ControlInput">
												<ObjectRef Name="sp_volume" ID="{PARAM}" WorkUnitID="{PARAM_WU}"/>
											</Reference>
											<Reference Name="Curve">
												<Custom>
													<Curve Name="" ID="{ids['curve']}">
														<PropertyList>
															<Property Name="Flags" Type="int32" Value="1"/>
														</PropertyList>
														<PointList>
															<Point>
																<XPos>0</XPos>
																<YPos>-48</YPos>
																<Flags>5</Flags>
															</Point>
															<Point>
																<XPos>50</XPos>
																<YPos>-12</YPos>
																<Flags>0</Flags>
															</Point>
															<Point>
																<XPos>100</XPos>
																<YPos>0</YPos>
																<Flags>37</Flags>
															</Point>
														</PointList>
													</Curve>
												</Custom>
											</Reference>
										</ReferenceList>
									</RTPC>
								</Local>
							</Reference>
						</ObjectList>
					</ObjectLists>
					<ActiveSourceList>
						<ActiveSource Name="{row['event']}" ID="{source_id}" Platform="Linked"/>
					</ActiveSourceList>
				</Sound>"""


def action_xml(name, event_id, action_id, short_id, action_type, target_name, target_id, target_wu, scope) -> str:
    scope_xml = ""
    if scope is not None:
        scope_xml = f'\n\t\t\t\t\t\t\t\t<Property Name="Scope" Type="int16" Value="{scope}"/>'
    return f"""
				<Event Name="{name}" ID="{event_id}">
					<ChildrenList>
						<Action Name="" ID="{action_id}" ShortID="{short_id}">
							<PropertyList>
								<Property Name="ActionType" Type="int16" Value="{action_type}"/>{scope_xml}
							</PropertyList>
							<ReferenceList>
								<Reference Name="Target">
									<ObjectRef Name="{target_name}" ID="{target_id}" WorkUnitID="{target_wu}"/>
								</Reference>
							</ReferenceList>
						</Action>
					</ChildrenList>
				</Event>"""


def guid_from(parent: str) -> str:
    # Derive a second id so the action id is stable for a given event id.
    hexed = parent.strip("{}").replace("-", "")
    value = (int(hexed, 16) + 1) & ((1 << 128) - 1)
    return "{%08X-%04X-%04X-%04X-%012X}" % (
        (value >> 96) & 0xFFFFFFFF,
        (value >> 80) & 0xFFFF,
        (value >> 64) & 0xFFFF,
        (value >> 48) & 0xFFFF,
        value & 0xFFFFFFFFFFFF,
    )


def ws_escape(name: str) -> str:
    return name.replace("\\", "\\\\").replace('"', '\\"')


def write_script(rows) -> None:
    books = {
        item["name"]: item.get("loc", "")
        for item in json.loads((VOICES / "books.json").read_text(encoding="utf-8"))
    }
    expanded = []
    seen = set()
    for row in rows:
        for key in (row["name"], books.get(row["name"], "")):
            key = key.lower()
            if not key or key in seen:
                continue
            seen.add(key)
            expanded.append({**row, "name": key})
    rows = expanded
    chunks = []
    size = 80
    for index in range(0, len(rows), size):
        body = []
        for row in rows[index : index + size]:
            body.append(
                f'\tif (bookName == "{ws_escape(row["name"])}") {{ return "{row["event"]}|{row["seconds"]}"; }}'
            )
        number = index // size
        chunks.append(
            "function SpokenPagesInfo%d(bookName : string) : string\n{\n%s\n\treturn \"\";\n}\n"
            % (number, "\n".join(body))
        )
    calls = "\n".join(
        f"\tfound = SpokenPagesInfo{i}(bookName);\n\tif (found != \"\") {{ return found; }}"
        for i in range(len(chunks))
    )
    text = (
        "// Generated from the rendered books. One line is event name and length in seconds.\n\n"
        + "\n".join(chunks)
        + "\nfunction SpokenPagesInfo(bookName : string) : string\n{\n\tvar found : string;\n"
        + calls
        + '\n\treturn "";\n}\n'
    )
    SCRIPT.parent.mkdir(parents=True, exist_ok=True)
    SCRIPT.write_text(text, encoding="utf-8")


def main() -> None:
    rows = load_rows()
    if not rows:
        raise SystemExit("no rendered books")
    rng = random.Random(SEED)
    used = {18422101}
    ids_for = []
    for row in rows:
        pack = {}
        for key in ("sound", "source"):
            pack[key] = guid(rng)
        for key in ("sound_short", "media", "event_short"):
            while True:
                value = rng.randrange(1, 2**31 - 1)
                if value not in used:
                    used.add(value)
                    pack[key] = value
                    break
        pack["event"] = guid(rng)
        pack["action"] = guid(rng)
        pack["rtpc"] = guid(rng)
        pack["curve"] = guid(rng)
        pack["rtpc_short"] = next_id(rng, used)
        ids_for.append(pack)

    sounds = "\n".join(sound_xml(row, ids) for row, ids in zip(rows, ids_for))
    actor = f"""<?xml version="1.0" encoding="utf-8"?>
<WwiseDocument Type="WorkUnit" ID="{ACTOR_WU}" SchemaVersion="119">
	<AudioObjects>
		<WorkUnit Name="Default Work Unit" ID="{ACTOR_WU}" PersistMode="Standalone">
			<ChildrenList>
				<ActorMixer Name="SpokenPages" ID="{MIXER}">
					<PropertyList/>
					<ReferenceList>
						<Reference Name="OutputBus">
							<ObjectRef Name="Master Audio Bus" ID="{BUS}" WorkUnitID="{BUS_WU}"/>
						</Reference>
					</ReferenceList>
					<ChildrenList>
{sounds}
					</ChildrenList>
				</ActorMixer>
			</ChildrenList>
		</WorkUnit>
	</AudioObjects>
</WwiseDocument>
"""
    ACTOR.write_text(actor, encoding="utf-8")

    events = []
    banks = []
    for row, ids in zip(rows, ids_for):
        bank_events = [(row["event"], ids["event"], ids["action"], ids["event_short"], 1, None)]
        for suffix, action_type in (("_s", 2), ("_p", 7), ("_r", 9)):
            bank_events.append(
                (row["event"] + suffix, guid(rng), guid(rng), next_id(rng, used), action_type, 1)
            )
        refs = []
        for name, event_id, action_id, short_id, action_type, scope in bank_events:
            events.append(
                action_xml(
                    name,
                    event_id,
                    action_id,
                    short_id,
                    action_type,
                    row["event"],
                    ids["sound"],
                    ACTOR_WU,
                    scope,
                )
            )
            refs.append(
                f'\t\t\t\t\t\t<ObjectRef Name="{name}" ID="{event_id}" WorkUnitID="{EVENT_WU}" Origin="Manual" Filter="7"/>'
            )
        bank_id = guid(rng)
        bank_short = next_id(rng, used)
        banks.append(
            f"""\t\t\t\t<SoundBank Name="{row['event']}" ID="{bank_id}" ShortID="{bank_short}">
					<ObjectInclusionList>
{chr(10).join(refs)}
					</ObjectInclusionList>
					<ObjectExclusionList/>
					<GameSyncExclusionList/>
				</SoundBank>"""
        )

    event_doc = f"""<?xml version="1.0" encoding="utf-8"?>
<WwiseDocument Type="WorkUnit" ID="{EVENT_WU}" SchemaVersion="119">
	<Events>
		<WorkUnit Name="Default Work Unit" ID="{EVENT_WU}" PersistMode="Standalone">
			<ChildrenList>
{"".join(events)}
			</ChildrenList>
		</WorkUnit>
	</Events>
</WwiseDocument>
"""
    EVENTS.write_text(event_doc, encoding="utf-8")

    bank = f"""<?xml version="1.0" encoding="utf-8"?>
<WwiseDocument Type="WorkUnit" ID="{BANK_WU}" SchemaVersion="119">
	<SoundBanks>
		<WorkUnit Name="Default Work Unit" ID="{BANK_WU}" PersistMode="Standalone">
			<ChildrenList>
{chr(10).join(banks)}
			</ChildrenList>
		</WorkUnit>
	</SoundBanks>
</WwiseDocument>
"""
    BANK.write_text(bank, encoding="utf-8")
    if not SKIP_SCRIPT:
        write_script(rows)
    print(f"books {len(rows)}")


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "script":
        write_script(load_rows())
        print("script", len(load_rows()))
    else:
        main()
