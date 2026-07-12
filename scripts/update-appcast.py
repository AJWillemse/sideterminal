#!/usr/bin/env python3
"""Insert a new <item> into appcast.xml for a SideTerminal release.

Called from scripts/release.sh after the DMG is built and signed with
Sparkle's `sign_update`. Keeps every previous <item> (Sparkle walks the
whole feed to offer intermediate updates), inserting the new one first
since Sparkle expects the newest release at the top.
"""
import os
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", SPARKLE_NS)
ET.register_namespace("dc", "http://purl.org/dc/elements/1.1/")


def sparkle_tag(name: str) -> str:
    return f"{{{SPARKLE_NS}}}{name}"


def main() -> None:
    path = os.environ["APPCAST_PATH"]
    version = os.environ["RELEASE_VERSION"]  # e.g. 1.0.2
    build = os.environ["BUILD"]               # e.g. 202601011200
    ed_signature = os.environ["ED_SIGNATURE"]
    length = os.environ["LENGTH"]
    download_url = os.environ["DOWNLOAD_URL"]
    min_system_version = os.environ.get("MIN_SYSTEM_VERSION", "14.0")

    tree = ET.parse(path)
    channel = tree.getroot().find("channel")
    if channel is None:
        raise SystemExit("appcast.xml has no <channel> element")

    item = ET.Element("item")

    title = ET.SubElement(item, "title")
    title.text = f"Version {version}"

    pub_date = ET.SubElement(item, "pubDate")
    pub_date.text = datetime.now(timezone.utc).strftime("%a, %d %b %Y %H:%M:%S +0000")

    min_os = ET.SubElement(item, sparkle_tag("minimumSystemVersion"))
    min_os.text = min_system_version

    enclosure = ET.SubElement(item, "enclosure")
    enclosure.set("url", download_url)
    enclosure.set("type", "application/octet-stream")
    enclosure.set(sparkle_tag("version"), build)
    enclosure.set(sparkle_tag("shortVersionString"), version)
    enclosure.set(sparkle_tag("edSignature"), ed_signature)
    enclosure.set("length", length)

    # Newest first: Sparkle only needs the top item to decide "is there an
    # update", but keeping history lets it walk older releases if needed.
    # Insert right before the first existing <item> (i.e. after all channel
    # metadata, whichever of title/link/description/language are present);
    # append at the end if this is the very first release entry.
    children = list(channel)
    existing_items = [i for i, child in enumerate(children) if child.tag == "item"]
    insert_at = existing_items[0] if existing_items else len(children)
    channel.insert(insert_at, item)

    tree.write(path, encoding="utf-8", xml_declaration=True)
    # ElementTree drops the file's leading comment; there isn't a clean way
    # to preserve it through parse+write, so this is a known, accepted
    # tradeoff for keeping the update logic simple.
    print(f"Added appcast entry for {version} (build {build})")


if __name__ == "__main__":
    main()
