
function I2 = linsrgb2rgb(I1)
    I2 = zeros(size(I1));
    for k = 1:3
        temp = I1(:,:,k);
        I2(:,:,k) = 12.92*temp.*(temp<=0.0031308)+(1.055*temp.^(1/2.4)-0.055).*(temp>0.0031308);
    end
end