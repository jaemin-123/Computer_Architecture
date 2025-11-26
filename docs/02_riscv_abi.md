# RISC-V ABI & 함수 호출 규약 (요약)

## 1. 레지스터 역할 (ABI)

| 레지스터 | 별칭 | 용도                         | 보존 규칙        |
|---------|------|------------------------------|------------------|
| x0      | zero | 항상 0                       | 읽기 전용        |
| x1      | ra   | return address               | caller-saved     |
| x2      | sp   | stack pointer                | callee가 원상복구 |
| x3      | gp   | global pointer               | 거의 안 건드림   |
| x4      | tp   | thread pointer               | 거의 안 건드림   |
| x5~x7   | t0~t2| 임시값 (temp)                | caller-saved     |
| x8      | s0/fp| saved / frame pointer        | callee-saved     |
| x9      | s1   | saved                        | callee-saved     |
| x10~x17 | a0~a7| 인자 / 반환값(주로 a0,a1)    | caller-saved     |
| x18~x27 | s2~s11| saved                        | callee-saved     |
| x28~x31 | t3~t6| 임시값 (temp)                | caller-saved     |

- **caller-saved**: `t0~t6`, `a0~a7`, `ra`  
  → 내가 함수를 *호출하기 전에* 필요하면 직접 스택에 저장.
- **callee-saved**: `s0~s11` (+ 사실상 `sp`, `fp`)  
  → 함수를 *구현하는 쪽*이 쓰기 전에 저장했다가 복구해야 함.

---

## 2. 함수 호출 규약 요약

### 2.1 인자 & 반환값

- 인자 1~8개: `a0~a7`에 순서대로 전달
- 9개 이상: 나머지는 **호출자 스택**에 저장해서 전달
- 반환값:
  - 기본: `a0`
  - 필요시 2개까지: `a0`, `a1`

### 2.2 호출자(caller)가 하는 일

1. 인자들을 `a0~a7`에 넣음  
2. 필요하면 `t` 레지스터, `a` 레지스터, `ra`를 스택에 백업  
3. `jal ra, func` 로 함수 호출

### 2.3 피호출자(callee)가 하는 일

**프롤로그(prologue)**

1. `sp`를 내려서 스택 프레임 할당  
2. 사용할 `s` 레지스터와 `ra` (필요하면 `fp`)를 스택에 저장  
3. `fp = sp + (frame_size)` 등으로 frame pointer 세팅(원하면)

**본문(body)**

- 연산 수행, 필요하면 다른 함수 호출

**에필로그(epilogue)**

1. 스택에서 `s` 레지스터, `ra`, `fp` 복구  
2. `sp`를 원래 값으로 되돌림  
3. 반환값을 `a0`(필요시 `a1`)에 넣음  
4. `jr ra` 또는 `ret` 으로 복귀

---

## 3. 스택 프레임 모양 (개념)

위 주소  
↓  

`[ 호출자 스택 프레임 ... ]`  
`[ 저장된 ra ]`        ← callee가 저장  
`[ 저장된 s0/fp ]`  
`[ 저장된 s1, s2, ... ]`  
`[ 로컬 변수 / 임시 버퍼 ]`  
`sp →` (현재 함수의 바닥)  

---

## 4. 최소 패턴 예시

```asm
# int add2(int x, int y) { return x + y; }

add2:
    add a0, a0, a1   # a0 = x + y
    ret              # jr ra 와 동일

# int f(int n) {
#   int s = 0;
#   s += add2(n, 1);
#   return s;
# }

f:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   s0, 8(sp)

    mv   s0, a0        # s0 = n
    mv   a0, s0        # a0 = n
    li   a1, 1         # a1 = 1
    jal  ra, add2      # add2(n,1) 호출, 결과는 a0

    mv   a0, a0        # 필요시 s 레지스터에 누적해도 됨 (여기선 바로 리턴)

    lw   s0, 8(sp)
    lw   ra, 12(sp)
    addi sp, sp, 16
    jr   ra

