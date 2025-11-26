int f, g, y;

int func(int a, int b){
    if (b<0)
        return (a+b);
    else
        return(a+func(a, b-1));
}

void main() {
    f=2;
    g=3;
    y=func(f,g);

    return;
}