document.getElementById("registrationForm").addEventListener("submit", function (e) {
    e.preventDefault();
  
    // Collect form data
    const formData = {
      firstName: document.getElementById("firstName").value,
      lastName: document.getElementById("lastName").value,
      mobileNumber: document.getElementById("mobileNumber").value,
      password: document.getElementById("password").value,
    };
  
    // Log data to console (replace with API call in real implementation)
    console.log("Form Data Submitted:", formData);
  
    // Clear form
    alert("Registration Successful!");
    this.reset();
  });
  
  function googleLogin() {
    alert("Google Login Clicked!");
    // Add Google OAuth logic here
  }
  
  function facebookLogin() {
    alert("Facebook Login Clicked!");
    // Add Facebook OAuth logic here
  }
  