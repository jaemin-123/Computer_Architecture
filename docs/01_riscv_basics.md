# RISC-V 기본 정리 (레지스터 / 명령어 / 포맷)

## 1. 레지스터와 이름

RISC-V는 32개의 32비트 정수 레지스터를 가진다.  
이들을 x0 ~ x31로 구성 되어있다.

### 1.1 주요 레지스터 그룹

- `zero`  
  - 항상 0인 읽기 전용 레지스터
- `ra` (return address)  
  - 함수 호출 후 되돌아갈 PC 저장
- `sp` (stack pointer)  
  - 스택의 최상단 주소
- `gp` (global pointer)
- `tp` (thread pointer)

- `t0 ~ t6` (temp)  
  - 임시 레지스터, **caller-saved**  
  - 호출하는 쪽에서 필요하면 저장

- `s0 ~ s11` (saved)  
  - 보존 레지스터, **callee-saved**  
  - 함수 안에서 쓰면, 원래 값 저장 후 복구해야 함

- `a0 ~ a7` (argument)  
  - 함수 인자 / 반환값
  - `a0, a1` : 반환값 주로 사용

이 ABI 규칙 때문에,
- “어떤 값은 t 레지스터에 대충 넣고 버려도 되는 값인지”
- “s 레지스터에 넣고 함수가 끝날 때까지 유지해야 하는 값인지”
를 구분해서 써야 한다.

---

## 2. 기본 산술 명령어 (R / I 타입)

예시:

```asm
add  s0, s1, s2   # s0 = s1 + s2 (R-type)
addi s0, s1, 32   # s0 = s1 + 32 (I-type, 즉시값)
```

- `add rd, rs1, rs2`  
  - 세 레지스터 모두 사용 → **R-type**
- `addi rd, rs1, imm`  
  - 즉시값(imm)을 포함 → **I-type**

RISC-V 기본 정수 명령어군(RV32I)은
R / I / S / B / U / J 6가지 포맷을 사용한다.

---

## 3. C 코드 `c = a + b;` 의 RISC-V 변환

메모리 상에 `a`, `b`, `c`가 있다고 할 때:

```c
c = a + b;
```

를 RISC-V로 옮기면 예를 들어:

```asm
# 1) a를 s0로 로드
lw  s0, a(zero)   # s0 = mem[a]

# 2) b를 s1로 로드
lw  s1, b(zero)   # s1 = mem[b]

# 3) 더하기
add s2, s0, s1    # s2 = s0 + s1

# 4) 결과 저장
sw  s2, c(zero)   # mem[c] = s2
```

여기서 `a(zero)`, `b(zero)`, `c(zero)`는
- 베이스 레지스터: `zero` (=0)
- 오프셋: `a`, `b`, `c` (링커가 실제 주소로 바꿔줌)

형식은 모두 다음 중 하나에 해당한다.
- `lw` : I-type
- `sw` : S-type
- `add` : R-type

---

## 4. 명령어 포맷 요약 (R / I / S / B / U / J)

32비트 명령어를 아래와 같이 나눈다. (비트 번호는 [31:0])

### 4.1 R-type (레지스터 연산)

```text
31      25 24   20 19   15 14   12 11    7 6      0
+--------+-------+-------+-------+--------+--------+
| funct7 |  rs2  |  rs1  | funct3|   rd   | opcode |
+--------+-------+-------+-------+--------+--------+
```

예: `add s0, s1, s2`

- `opcode` : 정수 연산
- `funct3`, `funct7` : 연산 종류(add/sub/and/or …)

---

### 4.2 I-type (즉시값, load, jalr 등)

```text
31           20 19   15 14   12 11    7 6      0
+--------------+-------+-------+--------+--------+
|   imm[11:0]  |  rs1  | funct3|   rd   | opcode |
+--------------+-------+-------+--------+--------+
```

예:
```asm
addi s0, s1, 32
lw   s0, 8(zero)
jalr ra, rs1, imm
```

---

### 4.3 S-type (store)

```text
31      25 24   20 19   15 14   12 11    7 6      0
+--------+-------+-------+-------+--------+--------+
|imm[11:5]|  rs2 |  rs1  | funct3|imm[4:0]| opcode|
+--------+-------+-------+-------+--------+--------+
```

예: `sw s2, 20(zero)`

- store는 즉시값을 두 부분으로 쪼개서 저장한다.

---

### 4.4 B-type (branch)

```text
31     25 24   20 19   15 14   12 11    7 6      0
+-------+-------+-------+-------+--------+--------+
|imm[12]|imm[10:5]| rs2 |  rs1  | funct3|imm[4:1]|imm[11]|opcode|
+-------+---------+-----+-------+-------+--------+------+------+
```

예: `beq s0, s1, target`

- 분기 대상 주소는 **PC-relative** (현재 PC에서 오프셋 더함)
- 실제 오프셋은 여러 비트 조각을 합쳐서 만든다.

---

### 4.5 U-type (lui, auipc)

```text
31                        12 11    7 6      0
+---------------------------+--------+--------+
|          imm[31:12]       |   rd   | opcode |
+---------------------------+--------+--------+
```

예:
```asm
lui   s2, 0xABCDE    # 상위 20비트 로드
auipc ra, imm20      # PC + imm20<<12 → ra
```

---

### 4.6 J-type (jal)

```text
31     12 11    7 6      0
+--------+--------+--------+
| imm[20:1]       |   rd   | opcode |
+--------+--------+--------+
```

예: `jal ra, label`

- `ra = PC + 4`
- `PC = PC + offset` (offset은 여러 조각의 imm을 조합해서 계산)

---

## 5. 메모리 접근과 pseudo 명령어

### 5.1 배열에서 값 읽기

```c
int a = mem[2];
```

메모리에서 4바이트 정수 배열이라고 하면 index 2는 offset 8이다.

pseudo:

```asm
lw a, 8(zero)          # a = mem[2]
```

실제로는 ABI에 따라 `a`는 보통 `s1`이나 `a0` 같은 레지스터일 것:

```asm
lw s1, 8(zero)
```

---

### 5.2 메모리에 값 쓰기

```c
mem[5] = 42;
```

pseudo:

```asm
sw 42, 20(zero)        # 이런 식 표기는 pseudo (즉시값 store)
```

실제 RISC-V에서는 store의 rs2에 **레지스터**가 들어가야 하므로:

```asm
addi t3, zero, 42      # t3 = 42 (I-type)
sw   t3, 20(zero)      # mem[5] = t3 (S-type)
```

---

## 6. 32비트 상수 로딩: `lui` + `addi`

32비트 상수를 한 번에 바로 쓸 수 없으므로, 상/하위로 나눠서 만든다.

예:

```c
int a = 0xABCDE123;
```

```asm
lui   s2, 0xABCDE      # s2[31:12] = 0xABCDE, 아래 12비트는 0
addi  s2, s2, 0x123    # s2 = 0xABCDE000 + 0x123 = 0xABCDE123
```

- `lui` : U-type
- `addi` : I-type

---

## 7. 분기 명령 `beq`

```asm
beq s0, s1, target
```

C로 보면:

```c
if (s0 == s1) goto target;
```

- 현재 명령의 PC 기준으로 offset(즉시값)을 더해서 분기  
- offset 계산은 어셈블러가 `target` 레이블 위치를 보고 자동으로 해줌  
- 하드웨어 입장에서는 B-type 포맷에 즉시값이 잘려 들어온 것을 조합해서
  `PC_next = PC + imm` 또는 `PC + 4`를 선택

---

## 8. 점프와 함수 호출: `jal` / `jalr`

### 8.1 j / jr pseudo 명령어

- `j label`  → 실제 명령: `jal x0, label`
- `jr x`     → 실제 명령: `jalr x0, x, 0`  
  - 예: `jr ra` 는 `jalr x0, ra, 0` 과 동일 (함수 리턴)

함수 호출:

```c
int main() {
    simple();
    ...
}

void simple() {
    return;
}
```

RISC-V 흐름:

1. `main`에서 `simple` 호출

   ```asm
   jal ra, simple   # ra = PC + 4, PC = simple
   ```

2. `simple` 함수 끝에서 복귀

   ```asm
   jalr zero, ra, 0 # PC = ra + 0 (return)
   ```

여기서 `ra`는 x1 레지스터.

---

## 9. `auipc` + `jalr`를 이용한 PC-relative call

먼 거리(또는 재배치 가능한 코드)로 점프할 때는 `auipc`와 `jalr` 조합을 사용한다.

대략적인 패턴:

```asm
# 1) 현재 PC 기준으로 상위 주소 계산
auipc ra, imm20         # ra = PC + (imm20 << 12)

# 2) 하위 즉시값 더해서 최종 주소 만들고 점프
jalr ra, ra, imm12      # ra = PC + 4, PC = (ra(old) + imm12)
```

- `auipc` : U-type, 현재 PC에 상위 20비트 즉시값을 더해 base address 생성
- `jalr` : I-type, base + 하위 12비트 더해 최종 점프 주소 구성 + 링크(ra ← PC+4)

이 패턴으로 “PC + 큰 오프셋” 위치의 함수를 호출할 수 있다.

---

이 문서는 칠판에 적어둔 내용(레지스터, 명령어 포맷, `lw/sw`, `lui+addi`, `beq`, `jal/jalr`, `auipc` 등)을 정리한 것이다.  
추가로 실습 코드나 예제는 `labs/` 디렉터리에서 따로 정리하면 된다.
