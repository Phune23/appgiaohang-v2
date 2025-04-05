import nodemailer from 'nodemailer';

//đăng ký tài khoàn sử dụng dịch vụ gửi email của google
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'hienxadoi2020@gmail.com', 
    pass: 'awhm hoti qatg qihf' 
  }
});

//Form gửi email
export const sendOTP = async (email, otp) => {
  const mailOptions = {
    from: 'Delivery Service',
    to: email,
    subject: 'Email Verification OTP to register',
    text: `Your OTP for email verification is: ${otp}`
  };

  return await transporter.sendMail(mailOptions);
};
// Remove sendShipperStatusNotification// export const sendShipperStatusNotification = async (email, status, name) => {//   // ...removed...// };