#!/bin/sh

# --------------------------------------------------
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PARENT_DIR="$(cd "$BASE_DIR/.." && pwd)"
NAME="$(basename "$BASE_DIR")"

SEQ="$PARENT_DIR/seqfiles/${NAME}_seq.in"
PDB="$BASE_DIR/step0/1/__END.pdb"
DREST="$BASE_DIR/drest.in"

# --------------------------------------------------
# 1. Compute sequence midpoints
# --------------------------------------------------
LENGTHS=$(awk '
$1=="ACE" {count=0; inpep=1; next}
$1=="NME" {print count; inpep=0}
inpep {count++}
' "$SEQ")

MID1=$(echo "$LENGTHS" | sed -n '1p' | awk '{print int(($1+1)/2)}')
MID2=$(echo "$LENGTHS" | sed -n '2p' | awk '{print int(($1+1)/2)}')

echo "Sequence midpoints:"
echo "  Chain A -> $MID1"
echo "  Chain B -> $MID2"

# --------------------------------------------------
# 2. Select midpoint CA atoms
# --------------------------------------------------
read ATOM1 ATOM2 <<EOF
$(awk -v m1="$MID1" -v m2="$MID2" '
$1=="ATOM" || $1=="HETATM" {
    atom=$3
    res=$4
    chain=$5

    if (atom!="CA") next
    if (res=="ACE" || res=="NME") next

    if (chain=="A") {
        countA++
        if (countA==(m1+1)) atomA=$2
    }
    if (chain=="B") {
        countB++
        if (countB==(m2+1)) atomB=$2
    }
}
END {print atomA, atomB}
' "$PDB")
EOF

echo "Central CA atom numbers:"
echo "  Chain A -> $ATOM1"
echo "  Chain B -> $ATOM2"

# --------------------------------------------------
# 3. Replace XXX XXX directly in drest.in
# --------------------------------------------------
sed -i.bak "s/XXX XXX/$ATOM1 $ATOM2/" "$DREST"

