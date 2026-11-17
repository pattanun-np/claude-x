# UX Writing — Global Product Copy Rules

Applies to **every screen, every feature, every project** unless a requirement directly
contradicts. Target quality: Apple-style product copy — สั้น, calm, precise, human, progressive.
Extends CLAUDE.md §3.4 (AI smells) and each project's i18n conventions.

<core>
## Core Principle
**Say what the user needs to know, at the moment they need to know it, in the fewest clear words possible.**
**Hide system complexity. Expose user consequences.**

UX ที่ดีไม่ใช่การอธิบายระบบให้ครบที่สุด — แต่คือการทำให้ผู้ใช้แทบไม่ต้องคิดว่าระบบข้างในทำงานอย่างไร.
</core>

<language>
## 1. Write for the user, not the system
Copy อธิบายจากมุมของ **สิ่งที่ผู้ใช้ต้องการทำ**.
- Prefer: อัตโนมัติ · ภาษา · การถอดเสียง · รับสายบน · โทรกลับ · ส่งอีกครั้ง · เชื่อมต่อใหม่ · เลือกทีม · เลือกหมายเลข
- Avoid: System Default · Runtime Mode · Provider Routing · Internal Retry · Fallback Strategy · Mobile RTC · Transport · Execution Type · Processing Pipeline
- ศัพท์เทคนิคที่ไม่จำเป็นต่อ **การตัดสินใจ** ของผู้ใช้ → ห้ามเป็น primary UI copy.

## 2. Prefer the shortest clear copy
สั้นที่สุดเท่าที่ความหมายยังครบ — ตัดทุกคำที่ไม่ช่วยให้เข้าใจหรือเลือกได้ดีขึ้น (ไม่ใช่ย่อจนคลุมเครือ).
- Bad: `เลือกผู้ให้บริการที่ต้องการใช้ในการประมวลผลการถอดเสียงสำหรับการสนทนานี้`
- Good: `เลือกวิธีถอดเสียง` / `การถอดเสียง`

## 9. Use human labels, not internal names
Internal enum ≠ user-facing label. `mobile_rtc` → **โทรผ่านแอป** · `system_default` → **อัตโนมัติ**.
**ห้ามเปลี่ยน internal enum เพียงเพราะ UX copy เปลี่ยน.**

## 10. Neutral, calm language
- Avoid: ผิดพลาดร้ายแรง · ระบบล้มเหลว · ไม่สามารถทำงานได้! · โปรดดำเนินการทันที · แพงกว่า · ช้ามาก · อันตราย
- Prefer: ลองอีกครั้ง · ยังเชื่อมต่อไม่ได้ · ต้องตรวจสอบเพิ่มเติม · อาจมีค่าใช้จ่ายสูงกว่า · ใช้เวลานานขึ้นเล็กน้อย
- ใช้ภาษารุนแรงเฉพาะเมื่อสถานการณ์รุนแรงจริง.

## 23. Use Thai naturally
ไทยใน UI ไม่ใช่การแปลตรงจาก English. ตัด **ทำการ** ออกเกือบทุกกรณี:
ทำการบันทึก→**บันทึก** · ทำการเลือก→**เลือก** · ดำเนินการลบ→**ลบ** · ทำการเชื่อมต่อ→**เชื่อมต่อ**

## 24. No polite particles in product UI
ไม่ใช้ กรุณา · โปรด · ครับ · ค่ะ เว้นแต่จำเป็นด้าน tone หรือ legal/compliance.
Bad `กรุณาเลือกภาษาที่ต้องการใช้งาน` → Good `เลือกภาษา`

## 25. Sentence case
หลีกเลี่ยง ALL CAPS และ Title Case แบบอังกฤษโดยไม่จำเป็น.
</language>

<structure>
## 3. One UI element, one message
โครงสร้างปกติ = `Title` + `Short supporting text`. เช่น `ElevenLabs Scribe` / `รวดเร็วและแม่นยำ`.
ห้ามยัด feature + limitation + implementation + pricing + retry + infra ไว้ใน description เดียว → ใช้ progressive disclosure.

## 4. Benefit first
Description ตอบ **"ตัวเลือกนี้ดีสำหรับอะไร?"** ไม่ใช่ "ระบบข้างในทำงานอย่างไร?".
- Bad: `ใช้ speech-to-speech model เพื่อประมวลผล audio track โดยตรง`
- Better: `ประมวลผลเสียงโดยตรง` — รายละเอียดเทคนิคไปอยู่ Learn more / tooltip / advanced.

## 5. Hide implementation details
ห้ามเป็น copy หลัก: connection recreation · worker behavior · queue internals · cache behavior ·
provider failover · API/database terminology · transport protocol · internal state name · retry engine · enum name.
- Bad: `สายที่ยาวมักจะ reconnect ระหว่างทาง`
- If the user truly needs it: `สายสนทนาที่ยาวมากอาจมีการเชื่อมต่อใหม่โดยอัตโนมัติ` — และแสดงเฉพาะหลังเลือก feature/provider นั้น.

## 6. Progressive disclosure by default
ลำดับ: สิ่งที่ต้องเลือก → ความแตกต่างหลัก → รายละเอียดเมื่อเลือกแล้ว → advanced settings เมื่อจำเป็น.
`OpenAI` / `เหมาะกับคำศัพท์เฉพาะ` → หลังเลือก: `คำศัพท์เฉพาะ` / `เพิ่มชื่อสินค้า ชื่อบุคคล หรือคำเฉพาะขององค์กร`

## 8. Avoid redundant context
อย่าพูดซ้ำสิ่งที่ section / page / component บอกอยู่แล้ว.
ใน section `การถอดเสียง` → ใช้ `xAI` ไม่ใช่ `xAI (ถอดเสียง)`. หน้า Call Settings ไม่ต้องใส่ "Call" ทุก label.

## 26. Don't repeat the title in the description
- Bad: `ภาษา` / `เลือกภาษาที่ต้องการใช้เป็นภาษา`
- Good: `ภาษา` / `เลือกภาษาหลักของการสนทนา`

## 27. Descriptions answer one useful question
เหมาะกับอะไร · มีผลอะไร · ควรรู้อะไรก่อนเลือก. ห้ามเป็น definition ที่ไม่มีประโยชน์.
- Bad: `Voicemail คือระบบรับข้อความเสียง` → Better: `รับข้อความเมื่อไม่มีคนรับสาย`

## 31. Information hierarchy (default)
Section title → optional 1-line section description → field/option title → 1-line description →
optional selected-state detail → optional advanced settings → optional contextual warning.
ห้ามวาง paragraph + technical note + warning + pricing + limitation ทั้งหมด **ก่อน** ผู้ใช้ได้ทำอะไร.

## 32. Copy density (default constraint, not a hard cap)
Section description 1 บรรทัด · option description 1 บรรทัด · form helper 1 บรรทัด · warning 1–2 บรรทัด ·
empty state = title + 1 short line · confirmation = title + 1 consequence · button 1–3 คำ.
อย่าบังคับตามจำนวนคำหากทำให้ความหมายเสีย.
</structure>

<components>
## 7. Defaults must feel safe
`อัตโนมัติ` + badge `แนะนำ` / `ระบบเลือกตัวเลือกที่เหมาะสมให้` — ไม่ใช่ `Use System Default` / `Inherit Global Configuration`.
**ห้ามเขียน "อัตโนมัติ" หรือ "ระบบเลือกให้" ถ้า implementation ไม่ได้ทำเช่นนั้นจริง** (see rule 30).

## 11. Warnings are not descriptions
Warning ปรากฏเมื่อ relevant — ไม่ใช่ก่อนผู้ใช้เลือก.
- Bad: `Provider A` / `เร็ว แต่มีโอกาส disconnect และแพงกว่า provider อื่น`
- Better: `Provider A` / `เหมาะกับงานแบบเรียลไทม์` → หลังเลือก: `ค่าใช้จ่าย` / `ตัวเลือกนี้อาจมีค่าใช้จ่ายสูงกว่าตัวเลือกทั่วไป`

## 12. Never explain pricing awkwardly
ห้าม: `คิดค่าบริการแบบเดียวกับ...` · `คิดตาม track...` · `แพงกว่าตัวด้านบน` · `ราคาจะแตกต่างกันไปตาม...`
ใช้: `อาจมีค่าใช้จ่ายสูงกว่า` · `คิดค่าบริการตามการใช้งาน` · หรือแสดงราคาจริงถ้าระบบมีข้อมูล.

## 13. Labels are usually nouns
ภาษา · หมายเลข · ทีม · เสียง · การถอดเสียง · เวลาทำการ · การโทรกลับ. Helper text ค่อยอธิบาย action/context.

## 14. Buttons describe the action
บันทึก · เพิ่มหมายเลข · สร้าง Agent · ส่งข้อความ · โทรกลับ · ลบ · เชื่อมต่อ · ทดสอบการโทร.
Avoid OK / Yes / Confirm / Continue เว้นแต่ context ชัดมากจริง. Destructive → ชื่อ action จริง (`ลบหมายเลข` ไม่ใช่ `ยืนยัน`).

## 15. Avoid "Are you sure?" dialogs
บอก: กำลังจะเกิดอะไร · ผลกระทบ · action ที่ชัดเจน.
- Bad: `คุณแน่ใจหรือไม่?` `[ยกเลิก] [ตกลง]`
- Good: `ลบหมายเลขนี้?` / `หมายเลขนี้จะไม่สามารถรับสายได้อีก` `[ยกเลิก] [ลบหมายเลข]`

## 16. Error messages must help recovery
ตอบ: เกิดอะไรขึ้น · ทำอะไรต่อได้.
- Bad: `Something went wrong` → Better: `ยังบันทึกการตั้งค่าไม่ได้ ลองอีกครั้ง` / `ยังเชื่อมต่อไม่ได้ ตรวจสอบข้อมูลแล้วลองอีกครั้ง`
- **ห้ามแสดง raw backend error ใน primary UI.**

## 17. Empty states need a next action
ไม่ใช่แค่ `ไม่มีข้อมูล`: `ยังไม่มีหมายเลข` / `เพิ่มหมายเลขเพื่อเริ่มรับสายและโทรออก` `[เพิ่มหมายเลข]`

## 19. Don't overuse badges
Badge เมื่อช่วย scan จริง (แนะนำ · ใหม่ · Beta · เรียลไทม์). Default ≤ 1 badge ต่อ item; ไม่ใช่ทุก row.

## 20. Don't overuse tooltips
Tooltip = supplemental only. ถ้าผู้ใช้ต้องรู้ **ก่อนตัดสินใจ** → แสดง inline.

## 21. Avoid long placeholder text
Placeholder ≠ helper text. Label `ชื่อ` · placeholder `เช่น Arm` · helper (ถ้าจำเป็น) `ชื่อนี้จะแสดงให้สมาชิกคนอื่นเห็น`.
Bad: `กรุณากรอกชื่อของผู้ใช้งานที่คุณต้องการเพิ่มเข้าสู่ระบบ`

## 33. Selection lists
Options น้อย + ความแตกต่างสำคัญ → radio list / compact selection cards / checkmark list (ไม่ใช่ dropdown ที่มี paragraph ยาว).
Options เยอะ → select / searchable combobox. Selected state ชัดด้วย checkmark · subtle background · accent — เลี่ยง heavy border/shadow.

## 34. Progressive settings
Provider- หรือ mode-specific settings แสดงเมื่อ relevant เท่านั้น. Provider ไม่รองรับ → **ซ่อน** field แทน disable + คำอธิบายยาว (เว้นแต่มีเหตุผลต้องให้เห็น).
</components>

<consistency>
## 18. No marketing copy inside product settings
Settings ≠ landing page. ห้าม: ดีที่สุด · ปฏิวัติวงการ · ทรงพลัง · สุดยอด · AI ขั้นสูง · next-generation · world-class. ใช้ factual copy.

## 22. Keep terminology consistent
คำเดียวกัน = คำเดียวกันทั้ง product. อย่าสลับ โทรกลับ/Callback/Call back · ผู้ให้บริการ/Provider/Service ·
ถอดเสียง/Transcribe/Transcript Processing · ทีม/Group/Department.
**ค้นหา terminology ที่มีอยู่ใน project ก่อนสร้างคำใหม่.**
> In messageeagle this is CI-enforced: `frontend/app/src/i18n/common-vocabulary.guard.test.ts`
> (`ARCHITECTURE_RAISE: DUPLICATE_COMMON_ACTION_TRANSLATION`) with a `common-vocabulary.baseline.json`
> ratchet. The ลบ/ลบออก/นำออก split is exactly the bug this rule prevents.

## 28. Don't surface architecture unless the user is configuring architecture
SIP · WebRTC · RTP · worker · queue · webhook · MCP · LLM · model routing → OK ใน developer/admin surface
ที่ target user เข้าใจและต้องใช้จริง. ใน end-user surface → แปลเป็น outcome เท่าที่ทำได้.

## 29. Advanced users can get advanced details
Apple-like ≠ ซ่อนทุกอย่าง. Hierarchy: simple default UI → Advanced → technical detail.
Developer/IT-admin audience ใช้ technical terms ได้ แต่ต้อง concise · consistent · contextual ·
ไม่ expose internal implementation ที่ไม่มีผลต่อการตั้งค่า.

## 30. UI copy must match real behavior
ห้ามเขียน copy ที่ "ดูดี" แต่ไม่ตรงกับระบบ:
- ห้าม `เลือกให้อัตโนมัติ` ถ้าระบบใช้ fixed provider.
- ห้าม `พร้อมใช้งาน` ถ้ายังไม่ได้ตรวจ health/status จริง.
- ห้าม `บันทึกแล้ว` ก่อน backend ยืนยัน success.
**UX writing ต้อง truthful ก่อน elegant เสมอ.**
</consistency>

<checklist>
## 35. Copy review checklist (before calling UI work done)
- ผู้ใช้เข้าใจโดยไม่รู้ architecture หรือไม่
- ตัดคำออกได้อีกหรือไม่
- มีคำ technical ที่ไม่จำเป็นหรือไม่
- copy ซ้ำกับ heading / context หรือไม่
- description บอกประโยชน์หรือผลกระทบจริงหรือไม่
- warning แสดงเฉพาะตอน relevant หรือไม่
- terminology ตรงกับส่วนอื่นของ product หรือไม่
- ภาษาไทยฟังเป็นธรรมชาติ หรือเป็นภาษาแปล
- action button บอก action จริงหรือไม่
- error บอกวิธีไปต่อหรือไม่
- copy ตรงกับ behavior จริงหรือไม่
- มี raw internal enum / state / API error หลุดออกมาหรือไม่
</checklist>

<implementation>
## Implementation Rule for Claude
เมื่อแก้หรือสร้าง UI ใหม่:
- ตรวจ existing terminology ก่อน · ตรวจ adjacent screens เพื่อรักษาความสม่ำเสมอ.
- ลด copy ที่เป็น implementation detail · ใช้ progressive disclosure สำหรับ advanced information.
- **ห้ามเปลี่ยน business logic เพื่อแก้ wording** เว้นแต่ requirement ระบุ.
- **ห้ามเปลี่ยน API enum / value / key เพียงเพราะ user-facing label เปลี่ยน.**
- ถ้ามี i18n ให้ใช้ translation system เดิม · **อย่า hardcode copy ใน component** ถ้า project มี translation layer.
- ตรวจ responsive layout หลังเปลี่ยนข้อความ.
- ถ้า copy เดิมขัดกับ behavior จริง → แก้ให้ truthful **และระบุ discrepancy**.
- พบ copy ที่ผิดกฎเดียวกันใน component เดียวกัน → แก้ให้สอดคล้องได้ โดยไม่ขยาย scope ไปทั้ง product.
- **ห้าม rewrite copy ทั้งระบบโดยอัตโนมัติเพียงเพราะพบกฎนี้** — ใช้เมื่อกำลังสร้างหรือแก้ surface นั้น (scope lock, CLAUDE.md §5.3).
</implementation>
